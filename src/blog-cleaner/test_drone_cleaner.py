"""
Tests for the DroneBlogCleaner class.

This module tests the functionality of the DroneBlogCleaner class,
focusing on API interaction, post retrieval, and deletion.
"""

import unittest
from unittest.mock import patch, Mock

from drone_cleaner import DroneBlogCleaner


class TestDroneBlogCleaner(unittest.TestCase):
  """Test cases for the DroneBlogCleaner class."""

  def setUp(self):
    """Set up test environment before each test."""
    self.ghost_url = "https://blog.example.com"
    self.api_key = "1234:5678abcdef"
    self.cleaner = DroneBlogCleaner(self.ghost_url, self.api_key)

  @patch('drone_cleaner.time.time')
  @patch('drone_cleaner.jwt.encode')
  def test_create_headers(self, mock_jwt_encode, mock_time):
    """Test that authentication headers are created correctly."""
    # Setup mocks
    mock_time.return_value = 1000
    mock_jwt_encode.return_value = "dummy_token"

    # Test
    headers = self.cleaner._create_headers()

    # Verify
    [id, _] = self.api_key.split(':')
    mock_jwt_encode.assert_called_once()

    # Check that encode was called with correct parameters
    call_args = mock_jwt_encode.call_args[0]
    self.assertEqual(call_args[0]['aud'], '/v5.0/admin/')
    self.assertEqual(call_args[0]['iat'], 1000)
    self.assertEqual(call_args[0]['exp'], 1300)  # 1000 + 5*60

    self.assertEqual(headers['Authorization'], 'Ghost dummy_token')
    self.assertEqual(headers['Content-Type'], 'application/json')

  @patch('drone_cleaner.requests.get')
  def test_get_all_posts_single_page(self, mock_get):
    """Test retrieving posts when all fit on a single page."""
    # Setup mock
    mock_response = Mock()
    mock_response.status_code = 200
    mock_response.json.return_value = {'posts': [
      {'id': '1', 'title': 'Post 1'},
      {'id': '2', 'title': 'Post 2'},
    ]}
    mock_get.return_value = mock_response

    # Test
    posts = self.cleaner.get_all_posts()

    # Verify
    mock_get.assert_called_once()
    self.assertEqual(len(posts), 2)
    self.assertEqual(posts[0]['id'], '1')
    self.assertEqual(posts[1]['title'], 'Post 2')

  @patch('drone_cleaner.requests.get')
  def test_get_all_posts_multiple_pages(self, mock_get):
    """Test retrieving posts when they span multiple pages."""
    # Create 2 pages of responses
    mock_response1 = Mock()
    mock_response1.status_code = 200
    mock_response1.json.return_value = {'posts': [{'id': '1'} for _ in range(100)]}

    mock_response2 = Mock()
    mock_response2.status_code = 200
    mock_response2.json.return_value = {'posts': [{'id': '2'} for _ in range(50)]}

    # Setup mock to return different responses on successive calls
    mock_get.side_effect = [mock_response1, mock_response2]

    # Test
    posts = self.cleaner.get_all_posts()

    # Verify
    self.assertEqual(mock_get.call_count, 2)
    self.assertEqual(len(posts), 150)

  @patch('drone_cleaner.requests.get')
  def test_get_all_posts_error(self, mock_get):
    """Test error handling when retrieving posts fails."""
    # Setup mock
    mock_response = Mock()
    mock_response.status_code = 401
    mock_response.text = "Unauthorized"
    mock_get.return_value = mock_response

    # Test
    posts = self.cleaner.get_all_posts()

    # Verify
    self.assertEqual(posts, [])

  @patch('drone_cleaner.requests.delete')
  def test_delete_post_success(self, mock_delete):
    """Test successful post deletion."""
    # Setup mock
    mock_response = Mock()
    mock_response.status_code = 204
    mock_delete.return_value = mock_response

    # Test
    result = self.cleaner.delete_post('post-123')

    # Verify
    mock_delete.assert_called_once()
    self.assertTrue(result)

  @patch('drone_cleaner.requests.delete')
  def test_delete_post_failure(self, mock_delete):
    """Test handling of failed post deletion."""
    # Setup mock
    mock_response = Mock()
    mock_response.status_code = 404
    mock_response.text = "Post not found"
    mock_delete.return_value = mock_response

    # Test
    result = self.cleaner.delete_post('post-999')

    # Verify
    self.assertFalse(result)

  @patch.object(DroneBlogCleaner, 'get_all_posts')
  @patch.object(DroneBlogCleaner, 'delete_post')
  def test_delete_all_posts(self, mock_delete_post, mock_get_all_posts):
    """Test the delete_all_posts method."""
    # Setup mocks
    mock_get_all_posts.return_value = [
      {'id': '1', 'title': 'Post 1'},
      {'id': '2', 'title': 'Post 2'},
      {'id': '3', 'title': 'Post 3'},
    ]
    mock_delete_post.side_effect = [True, False, True]  # Second post fails

    # Test
    self.cleaner.delete_all_posts()

    # Verify
    self.assertEqual(mock_delete_post.call_count, 3)
    mock_delete_post.assert_any_call('1')
    mock_delete_post.assert_any_call('2')
    mock_delete_post.assert_any_call('3')

  @patch.object(DroneBlogCleaner, 'get_all_posts')
  def test_delete_all_posts_no_posts(self, mock_get_all_posts):
    """Test delete_all_posts when no posts are found."""
    # Setup mock
    mock_get_all_posts.return_value = []

    # Test
    self.cleaner.delete_all_posts()  # Should not raise any exceptions


if __name__ == '__main__':
  unittest.main()
