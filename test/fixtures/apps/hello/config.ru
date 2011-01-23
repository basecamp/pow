run lambda { |env|
  case env['PATH_INFO']
  when '/redirect'
    require 'rack/request'
    request = Rack::Request.new(env)
    location = "#{request.scheme}://#{request.host}"
    location << ":#{request.port}" if request.port != 80
    location << "/"
    [302, {'Location' => location, 'Content-Type' => 'text/plain', 'Content-Length' => '0'}, ['']]
  else
    [200, {'Content-Type' => 'text/plain', 'Content-Length' => '5'}, ['Hello']]
  end
}
