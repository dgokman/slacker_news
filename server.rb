require 'sinatra'
require 'sinatra/reloader'
require 'csv'
require 'redis'

def get_connection
  if ENV.has_key?("REDISCLOUD_URL")
    Redis.new(url: ENV["REDISCLOUD_URL"])
  else
    Redis.new
  end
end

def find_articles
  redis = get_connection
  serialized_articles = redis.lrange("slacker:articles", 0, -1)

  articles = []

  serialized_articles.each do |article|
    articles << JSON.parse(article, symbolize_names: true)
  end

  articles
end

def save_article(url, title, description)
  article = { url: url, title: title, description: description }

  redis = get_connection
  redis.rpush("slacker:articles", article.to_json)
end

def get_articles
  articles = []
  CSV.foreach("articles.csv") do |row|
    articles << {title: row[0],
    url: row[1],
    description: row[2]}
  end
 articles
end

get "/" do
  @articles = get_articles
  erb :index
end

get "/submit" do

  erb :submit
end

post "/articles" do
  @articles = get_articles
  title = params["title"]
  url = params["url"]
  description = params["description"]
  CSV.open("articles.csv","a") do |csv|
    csv << [title, url, description]
  end
  redirect '/'

end


