# app.py
from flask import Flask, jsonify, request, Response
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
import logging
import logging_loki

logging_loki.emitter.LokiEmitter.level_tag = "level"

handler = logging_loki.LokiHandler(
    url="http://loki:3100/loki/api/v1/push",
    version="1",
)

logger = logging.getLogger()
logger.addHandler(handler)
logger.setLevel(logging.INFO)


app = Flask(__name__)

REQUEST_COUNT = Counter(
    "demo_requests_total", "Total number of requests processed", ["method", "endpoint"]
)
NEW_POSTS_COUNT = Counter("demo_posts_added", "Number of posts added")
DELETED_POSTS_COUNT = Counter("demo_posts_deleted", "Number of posts deleted")

posts = []


@app.before_request
def before_request():
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.path,
    ).inc()


@app.route("/health")
def health():
    return "OK"


@app.route("/metrics")
def metrics():
    data = generate_latest()
    return Response(data, mimetype=CONTENT_TYPE_LATEST)


@app.route("/posts", methods=["GET"])
def list_posts():
    return jsonify([i for i in range(len(posts)) if "revoked" not in posts[i]]), 200


@app.route("/posts/<int:post_id>", methods=["GET"])
def view_post(post_id):
    if post_id not in range(len(posts)):
        return jsonify({"error": "Post not found"}), 404
    if "revoked" in posts[post_id]:
        return jsonify(posts[post_id]), 410
    return jsonify(posts[post_id]), 200


@app.route("/posts", methods=["POST"])
def publish_post():
    data = request.get_json()
    if (
        type(data) != dict
        or set(data) != set(["author", "title", "body"])
        or any(type(data[f]) != str for f in data)
    ):
        return jsonify({"error": "Invalid payload"}), 400

    posts.append(data)
    NEW_POSTS_COUNT.inc()
    logging.info(f'New post: "{data["author"]} - {data["title"]}"')

    return jsonify(len(posts) - 1), 201


@app.route("/posts/<int:post_id>", methods=["PUT"])
def update_post(post_id):
    if post_id not in range(len(posts)):
        return jsonify({"error": "Post not found"}), 404

    data = request.get_json()
    if (
        type(data) != dict
        or set(data) != set(["author", "title", "body"])
        or any(type(data[f]) != str for f in data)
    ):
        return jsonify({"error": "Invalid payload"}), 400

    old = posts[post_id]

    if old["author"] != data["author"]:
        logging.error(
            f'Attempt to change authorship of the post "{old["author"]} - {old["title"]}"'
        )
        return jsonify({"error": "Forbidden"}), 403

    posts[post_id] = data
    logging.info(f'Post "{old["author"]} - {old["title"]}" was updated')
    return jsonify(None), 200


@app.route("/posts/<int:post_id>", methods=["DELETE"])
def revoke_post(post_id):
    if post_id not in range(len(posts)):
        return jsonify({"error": "Post not found"}), 404

    old = posts[post_id]
    if "revoked" in old:
        logging.warn(
            f'Attempt to revoke already revoked post "{old["author"]} - {old["title"]}"'
        )
        return jsonify({"error": "Post already was revoked"}), 410
    posts[post_id] = {
        "author": old["author"],
        "title": f"Revoked - {old['title']}",
        "body": "The post was revoked",
        "revoked": True,
    }
    DELETED_POSTS_COUNT.inc()
    logging.info(f'Post "{old["author"]} - {old["title"]}" was revoked')
    return jsonify(None), 204


if __name__ == "__main__":
    app.run()
