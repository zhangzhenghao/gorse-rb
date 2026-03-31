require_relative '../lib/gorse'

require 'test/unit'
require 'time'

GORSE_ENDPOINT = 'http://127.0.0.1:8088'
GORSE_API_KEY = 'zhenghaoz'

class TestGorse < Test::Unit::TestCase

  def setup
    @client = Gorse.new(GORSE_ENDPOINT, GORSE_API_KEY)
  end

  def test_users
    data = @client.get_users(n: 3)
    cursor = data['Cursor']
    users = data['Users']
    assert(cursor && cursor.length > 0)
    assert_equal('1', users[0]['UserId'])
    assert_equal(24, users[0]['Labels']['age'])
    assert_equal("technician", users[0]['Labels']['occupation'])

    user = { 'UserId' => '1000', 'Labels' => { 'gender' => 'M', 'occupation' => 'engineer' }, 'Comment' => 'zhenghaoz' }
    r = @client.insert_user(user)
    assert_equal(1, r.row_affected)
    resp = @client.get_user('1000')
    assert_equal(user, resp)
    r = @client.delete_user('1000')
    assert_equal(1, r.row_affected)
    begin
      @client.get_user('1000')
      flunk('should raise 404')
    rescue => e
      assert_match(/404/, e.message)
    end
  end

  def test_items
    data = @client.get_items(n: 3)
    cursor = data['Cursor']
    items = data['Items']
    assert(cursor && cursor.length > 0)
    assert_equal('1', items[0]['ItemId'])
    assert_equal(['Animation', "Children's", 'Comedy'], items[0]['Categories'])
    assert_equal('1995-01-01T00:00:00Z', items[0]['Timestamp'])
    assert_equal('Toy Story (1995)', items[0]['Comment'])

    now = Time.now.utc.iso8601
    item = {
      'ItemId' => '2000',
      'IsHidden' => true,
      'Labels' => { 'embedding' => [0.1, 0.2, 0.3] },
      'Categories' => ['Comedy', 'Animation'],
      'Timestamp' => now,
      'Comment' => 'Minions (2015)'
    }
    r = @client.insert_item(item)
    assert_equal(1, r.row_affected)
    resp = @client.get_item('2000')
    assert_equal(item, resp)

    r = @client.update_item('2000', { 'Comment' => '小黄人 (2015)' })
    assert_equal(1, r.row_affected)
    resp = @client.get_item('2000')
    assert_equal('小黄人 (2015)', resp['Comment'])

    r = @client.delete_item('2000')
    assert_equal(1, r.row_affected)
    begin
      @client.get_item('2000')
      flunk('should raise 404')
    rescue => e
      assert_match(/404/, e.message)
    end
  end

  def test_feedback
    @client.insert_user({ 'UserId' => '2000' })

    now = Time.now.utc.iso8601
    feedbacks = [
      { 'FeedbackType' => 'watch', 'UserId' => '2000', 'ItemId' => '1', 'Value' => 1.0, 'Timestamp' => now, 'Comment' => '' },
      { 'FeedbackType' => 'watch', 'UserId' => '2000', 'ItemId' => '1060', 'Value' => 2.0, 'Timestamp' => now, 'Comment' => '' },
      { 'FeedbackType' => 'watch', 'UserId' => '2000', 'ItemId' => '11', 'Value' => 3.0, 'Timestamp' => now, 'Comment' => '' }
    ]
    feedbacks.each { |fb| @client.delete_feedbacks(fb['UserId'], fb['ItemId']) }
    r = @client.insert_feedback(feedbacks)
    assert_equal(3, r.row_affected)

    user_feedback = @client.list_feedbacks('watch', '2000')
    assert_equal(feedbacks.length, user_feedback.length)

    r = @client.delete_feedback('watch', '2000', '1')
    assert_equal(1, r.row_affected)
    user_feedback = @client.list_feedbacks('watch', '2000')
    assert_equal(2, user_feedback.length)
  end

  def test_item_to_item
    neighbors = @client.get_neighbors('1', n: 3)
    assert_equal('1060', neighbors[0]['Id'])
    assert_equal('404', neighbors[1]['Id'])
    assert_equal('1219', neighbors[2]['Id'])
  end

  def test_recommend
    @client.insert_user({ 'UserId' => '3000' })
    recommendations = @client.get_recommend('3000', n: 3)
    assert_equal(3, recommendations.length)
    assert_equal('315', recommendations[0]['Id'])
    assert_equal('1432', recommendations[1]['Id'])
    assert_equal('918', recommendations[2]['Id'])
  end

end