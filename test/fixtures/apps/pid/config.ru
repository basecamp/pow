run lambda {
  body = Process.pid.to_s
  [200, {'Content-Type' => 'text/plain', 'Content-Length' => body.length.to_s}, [body]]
}
