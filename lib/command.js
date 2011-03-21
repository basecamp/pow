var pow = require("..");
process.title = "pow";

var daemon = new pow.Daemon(new pow.Configuration);
daemon.start();
