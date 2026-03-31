require 'json'
require 'net/http'
require 'uri'
require 'time'

class Feedback
  def initialize(feedback_type, user_id, item_id, value, timestamp)
    @feedback_type = feedback_type
    @user_id = user_id
    @item_id = item_id
    @value = value
    @timestamp = timestamp
  end

  def to_json(options = {})
    data = {
      'FeedbackType' => @feedback_type,
      'UserId' => @user_id,
      'ItemId' => @item_id,
    }
    data['Value'] = @value unless @value.nil?
    data['Timestamp'] = @timestamp
    JSON.generate(data)
  end
end

class RowAffected
  def initialize(row_affected)
    @row_affected = row_affected
  end

  def self.from_json(string)
    data = JSON.load string
    self.new data['RowAffected']
  end

  attr_reader :row_affected
end

class Score
  def initialize(id, score)
    @id = id
    @score = score
  end

  def self.from_json(string)
    data = JSON.load string
    data.map { |h| Score.new(h['Id'], h['Score']) }
  end

  attr_reader :id, :score
end

class User
  def initialize(user_id:, labels: nil, comment: nil)
    @user_id = user_id
    @labels = labels
    @comment = comment
  end

  def to_h
    { 'UserId' => @user_id, 'Labels' => @labels, 'Comment' => @comment }
  end

  def to_json(*_args)
    JSON.generate(to_h)
  end

  def self.from_json(string)
    h = JSON.load string
    User.new(user_id: h['UserId'], labels: h['Labels'], comment: h['Comment'])
  end

  attr_reader :user_id, :labels, :comment
end

class UserPatch
  def initialize(labels: nil, comment: nil)
    @labels = labels
    @comment = comment
  end

  def to_json(*_args)
    data = {}
    data['Labels'] = @labels unless @labels.nil?
    data['Comment'] = @comment unless @comment.nil?
    JSON.generate(data)
  end
end

class UserIterator
  def initialize(cursor, users)
    @cursor = cursor
    @users = users
  end

  def self.from_json(string)
    h = JSON.load string
    users = (h['Users'] || []).map { |u| User.new(user_id: u['UserId'], labels: u['Labels'], comment: u['Comment']) }
    UserIterator.new(h['Cursor'], users)
  end

  attr_reader :cursor, :users
end

class Item
  def initialize(item_id:, is_hidden: nil, labels: nil, categories: nil, timestamp: nil, comment: nil)
    @item_id = item_id
    @is_hidden = is_hidden
    @labels = labels
    @categories = categories
    @timestamp = timestamp
    @comment = comment
  end

  def to_h
    data = { 'ItemId' => @item_id }
    data['IsHidden'] = @is_hidden unless @is_hidden.nil?
    data['Labels'] = @labels unless @labels.nil?
    data['Categories'] = @categories unless @categories.nil?
    data['Timestamp'] = @timestamp unless @timestamp.nil?
    data['Comment'] = @comment unless @comment.nil?
    data
  end

  def to_json(*_args)
    JSON.generate(to_h)
  end

  def self.from_json(string)
    h = JSON.load string
    Item.new(
      item_id: h['ItemId'],
      is_hidden: h['IsHidden'],
      labels: h['Labels'],
      categories: h['Categories'],
      timestamp: h['Timestamp'],
      comment: h['Comment']
    )
  end

  attr_reader :item_id, :is_hidden, :labels, :categories, :timestamp, :comment
end

class ItemPatch
  def initialize(is_hidden: nil, categories: nil, timestamp: nil, labels: nil, comment: nil)
    @is_hidden = is_hidden
    @categories = categories
    @timestamp = timestamp
    @labels = labels
    @comment = comment
  end

  def to_json(*_args)
    data = {}
    data['IsHidden'] = @is_hidden unless @is_hidden.nil?
    data['Categories'] = @categories unless @categories.nil?
    data['Timestamp'] = @timestamp unless @timestamp.nil?
    data['Labels'] = @labels unless @labels.nil?
    data['Comment'] = @comment unless @comment.nil?
    JSON.generate(data)
  end
end

class ItemIterator
  def initialize(cursor, items)
    @cursor = cursor
    @items = items
  end

  def self.from_json(string)
    h = JSON.load string
    items = (h['Items'] || []).map do |it|
      Item.new(
        item_id: it['ItemId'],
        is_hidden: it['IsHidden'],
        labels: it['Labels'],
        categories: it['Categories'],
        timestamp: it['Timestamp'],
        comment: it['Comment']
      )
    end
    ItemIterator.new(h['Cursor'], items)
  end

  attr_reader :cursor, :items
end

class Gorse
  def initialize(endpoint, api_key = "")
    @endpoint = endpoint
    @api_key = api_key
  end

  def insert_feedback(feedback)
    response = request('POST', '/api/feedback', feedback)
    RowAffected.from_json(response)
  end

  def list_feedbacks(feedback_type, user_id)
    JSON.parse(request('GET', "/api/user/#{escape(user_id)}/feedback/#{escape(feedback_type)}"))
  end

  def delete_feedback(feedback_type, user_id, item_id)
    RowAffected.from_json(request('DELETE', "/api/feedback/#{escape(feedback_type)}/#{escape(user_id)}/#{escape(item_id)}"))
  end

  def delete_feedbacks(user_id, item_id)
    RowAffected.from_json(request('DELETE', "/api/feedback/#{escape(user_id)}/#{escape(item_id)}"))
  end

  # Get recommendation for a user.
    end
    cat_seg = (category || '').to_s
    qs = []
    qs << ["n", n] unless n.nil?
    qs << ["offset", offset] unless offset.nil?
    query = qs.map { |k, v| "#{k}=#{URI.encode_www_form_component(v.to_s)}" }.join('&')
    path = "/api/recommend/#{escape(user_id)}/#{cat_seg}"
    path += "?#{query}" unless query.empty?
    JSON.parse(request('GET', path))
  end

  # Get recommendation with scores for a user.
  # Uses X-API-Version: 2 header to return scores.
  def get_recommend(user_id, category: nil, n: nil, offset: nil)
    cat_seg = (category || '').to_s
    qs = []
    qs << ["n", n] unless n.nil?
    qs << ["offset", offset] unless offset.nil?
    query = qs.map { |k, v| "#{k}=#{URI.encode_www_form_component(v.to_s)}" }.join('&')
    path = "/api/recommend/#{escape(user_id)}/#{cat_seg}"
    path += "?#{query}" unless query.empty?
    JSON.parse(request('GET', path, nil, { 'X-API-Version' => '2' }))
  end

  def get_latest_items(user_id: nil, category: nil, n:, offset: 0)
    category_path = category && !category.empty? ? "/#{escape(category)}" : ''
    qs = [["n", n], ["offset", offset]]
    qs << ["user-id", user_id] unless user_id.nil? || user_id.empty?
    query = qs.map { |k, v| "#{k}=#{URI.encode_www_form_component(v.to_s)}" }.join('&')
    path = "/api/latest#{category_path}?#{query}"
    JSON.parse(request('GET', path))
  end

  def session_recommend(feedbacks, n:)
    path = "/api/session/recommend?n=#{n}"
    JSON.parse(request('POST', path, feedbacks))
  end

  def get_neighbors(item_id, n:)
    JSON.parse(request('GET', "/api/item/#{escape(item_id)}/neighbors?n=#{n}"))
  end

  def get_neighbors_category(item_id, category:, n:, offset: 0)
    path = "/api/item/#{escape(item_id)}/neighbors/#{escape(category)}?n=#{n}&offset=#{offset}"
    JSON.parse(request('GET', path))
  end

  def get_neighbors_users(user_id, n:, offset: 0)
    path = "/api/user/#{escape(user_id)}/neighbors?n=#{n}&offset=#{offset}"
    JSON.parse(request('GET', path))
  end

  # User APIs
  def insert_user(user)
    RowAffected.from_json(request('POST', '/api/user', user))
  end

  def insert_users(users)
    RowAffected.from_json(request('POST', '/api/users', users))
  end

  def update_user(user_id, user_patch)
    RowAffected.from_json(request('PATCH', "/api/user/#{escape(user_id)}", user_patch))
  end

  def get_user(user_id)
    JSON.parse(request('GET', "/api/user/#{escape(user_id)}"))
  end

  def get_users(n:, cursor: '')
    JSON.parse(request('GET', "/api/users?n=#{n}&cursor=#{URI.encode_www_form_component(cursor)}"))
  end

  def delete_user(user_id)
    RowAffected.from_json(request('DELETE', "/api/user/#{escape(user_id)}"))
  end

  # Item APIs
  def insert_item(item)
    RowAffected.from_json(request('POST', '/api/item', item))
  end

  def insert_items(items)
    RowAffected.from_json(request('POST', '/api/items', items))
  end

  def update_item(item_id, item_patch)
    RowAffected.from_json(request('PATCH', "/api/item/#{escape(item_id)}", item_patch))
  end

  def get_item(item_id)
    JSON.parse(request('GET', "/api/item/#{escape(item_id)}"))
  end

  def get_items(n:, cursor: '')
    JSON.parse(request('GET', "/api/items?n=#{n}&cursor=#{URI.encode_www_form_component(cursor)}"))
  end

  def delete_item(item_id)
    RowAffected.from_json(request('DELETE', "/api/item/#{escape(item_id)}"))
  end

  private

  def escape(s)
    URI.encode_www_form_component(s.to_s)
  end

  def request(method, path, body = nil, extra_headers = {})
    base = @endpoint.end_with?('/') ? @endpoint : @endpoint + '/'
    uri = URI.join(base, path.sub(/^\//, ''))
    headers = { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
    headers['X-API-Key'] = @api_key if @api_key && !@api_key.empty?
    headers.merge!(extra_headers)

    req = case method.upcase
          when 'GET' then Net::HTTP::Get.new(uri, headers)
          when 'POST' then Net::HTTP::Post.new(uri, headers)
          when 'PATCH' then Net::HTTP::Patch.new(uri, headers)
          when 'DELETE' then Net::HTTP::Delete.new(uri, headers)
          else raise "Unsupported method #{method}"
          end
    if body && %w[POST PATCH].include?(method.upcase)
      payload = body.is_a?(String) ? body : JSON.generate(body)
      req.body = payload
    end
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |h|
      h.request(req)
    end
    unless response.is_a?(Net::HTTPSuccess)
      raise "HTTP #{response.code}: #{response.body}"
    end
    response.body
  end
end
