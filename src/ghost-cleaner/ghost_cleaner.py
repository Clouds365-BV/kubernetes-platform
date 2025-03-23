import os
import sys
import time

import jwt
import requests


class GhostBlogCleaner:
    def __init__(self, ghost_url, api_key):
        """Initialize with Ghost blog URL and Admin API key"""
        self.ghost_url = ghost_url.rstrip('/')
        self.api_key = api_key
        self.admin_api_url = f"{self.ghost_url}/ghost/api/admin"
        self.version = "v5.0"  # Ghost API version
        self.headers = self._create_headers()

    def _create_headers(self):
        """Create authentication headers for Admin API"""
        [id, secret] = self.api_key.split(':')

        # Create token
        iat = int(time.time())
        header = {'alg': 'HS256', 'typ': 'JWT', 'kid': id}
        payload = {'iat': iat, 'exp': iat + 5 * 60, 'aud': '/v5.0/admin/'}

        token = jwt.encode(payload, bytes.fromhex(secret), algorithm='HS256', headers=header)

        return {
            'Authorization': f'Ghost {token}',
            'Content-Type': 'application/json'
        }

    def get_all_posts(self):
        """Get all posts from the blog"""
        posts = []
        page = 1
        limit = 100  # Max number of posts per page

        while True:
            url = f"{self.admin_api_url}/{self.version}/posts/?limit={limit}&page={page}"
            response = requests.get(url, headers=self.headers)

            if response.status_code != 200:
                print(f"Error fetching posts: {response.status_code}")
                print(response.text)
                return []

            result = response.json()
            batch = result.get('posts', [])

            if not batch:
                break

            posts.extend(batch)
            print(f"Fetched {len(batch)} posts (page {page})")

            if len(batch) < limit:
                break

            page += 1

        return posts

    def delete_post(self, post_id):
        """Delete a post by ID"""
        url = f"{self.admin_api_url}/{self.version}/posts/{post_id}/"
        response = requests.delete(url, headers=self.headers)

        if response.status_code not in [204, 200]:
            print(f"Failed to delete post {post_id}: {response.status_code}")
            print(response.text)
            return False

        return True

    def delete_all_posts(self):
        """Delete all posts in the blog"""
        posts = self.get_all_posts()

        if not posts:
            print("No posts found to delete.")
            return

        print(f"Found {len(posts)} posts. Starting deletion...")

        success_count = 0
        failure_count = 0

        for post in posts:
            post_id = post['id']
            title = post.get('title', 'Untitled')

            print(f"Deleting post: {title} (ID: {post_id})")

            if self.delete_post(post_id):
                success_count += 1
                print(f"Successfully deleted post: {title}")
            else:
                failure_count += 1

        print(f"Deletion complete. Successfully deleted: {success_count}, Failed: {failure_count}")


def main():
    ghost_url = os.environ.get('GHOST_URL')
    api_key = os.environ.get('GHOST_ADMIN_API_KEY')

    if not ghost_url or not api_key:
        print("Error: GHOST_URL and GHOST_ADMIN_API_KEY environment variables are required")
        sys.exit(1)

    print(f"Connecting to Ghost blog at {ghost_url}")

    cleaner = GhostBlogCleaner(ghost_url, api_key)
    cleaner.delete_all_posts()


if __name__ == "__main__":
    main()
