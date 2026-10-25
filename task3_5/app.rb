require "sinatra"
require "net/http"
require "json"
require "time"

API_URL = "https://api.twelvedata.com"
API_KEY = ENV.fetch("TD_KEY")
CACHE_TTL = 60
CACHE = {}
CACHE_LOCK = Mutex.new

RANGES = {
  "1d" => { interval: "5min",  outputsize: 78 },
  "5d" => { interval: "30min", outputsize: 65 },
  "1w" => { interval: "1h",    days: 7 },
  "1m" => { interval: "1day",  days: 30 },
  "1y" => { interval: "1day",  days: 365 }
}

helpers do
  def twelve_data(path, query)
    cache_key = "#{path}?#{URI.encode_www_form(query)}"
    cached = CACHE_LOCK.synchronize do
      entry = CACHE[cache_key]
      entry[:data] if entry && Time.now - entry[:at] < CACHE_TTL
    end
    return cached if cached

    uri = URI("#{API_URL}/#{path}")
    uri.query = URI.encode_www_form(query.merge(apikey: API_KEY))
    data = JSON.parse(Net::HTTP.get(uri))

    if data["status"] == "error"
      status_code = data["code"] == 429 ? 429 : 502
      halt status_code, { "Content-Type" => "application/json" }, { error: data["message"] }.to_json
    end

    CACHE_LOCK.synchronize { CACHE[cache_key] = { at: Time.now, data: data } }
    data
  end
end

get "/" do
  send_file File.join(settings.public_folder, "index.html")
end

get "/api/search" do
  content_type :json
  q = params["q"].to_s.strip
  return "[]" if q.length < 2

  results = twelve_data("symbol_search", symbol: q, outputsize: 30)["data"] || []
  results
    .select { |s| s["country"] == "United States" }
    .uniq { |s| s["symbol"] }
    .first(10)
    .map { |s| { symbol: s["symbol"], name: s["instrument_name"], exchange: s["exchange"] } }
    .to_json
end

get "/api/series" do
  content_type :json
  range = RANGES[params["range"]]
  symbol = params["symbol"].to_s.upcase
  halt 400, { error: "Unknown range" }.to_json unless range
  halt 400, { error: "Invalid symbol" }.to_json unless symbol.match?(/\A[A-Z0-9.\-]{1,10}\z/)

  query = { symbol: symbol, interval: range[:interval], order: "asc" }
  if range[:days]
    query[:start_date] = (Date.today - range[:days]).to_s
  else
    query[:outputsize] = range[:outputsize]
  end

  (twelve_data("time_series", query)["values"] || []).map do |v|
    {
      time: Time.parse("#{v['datetime']} UTC").to_i,
      open: v["open"].to_f, high: v["high"].to_f,
      low: v["low"].to_f, close: v["close"].to_f
    }
  end.to_json
end