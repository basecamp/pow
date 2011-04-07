require "json"

run lambda {
  body = ENV.keys.grep(/^POW/).inject({}) { |e, k| e.merge(k => ENV[k]) }.to_json
  [200, {'Content-Type' => 'text/plain', 'Content-Length' => body.length.to_s}, [body]]
}
