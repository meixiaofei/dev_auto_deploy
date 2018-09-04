var fs = require('fs');
var chokidar = require('chokidar');
var exec = require('child_process').exec;
var filePath = 'default';

// One-liner for current directory, ignores .dotfiles
chokidar.watch('tmp', {ignored: /(^|[\/\\])\../}).on('all', function (event, path) {
    console.log(event, path);
    if (event == 'add') {
        filePath = __dirname + '/' + path;
        fs.exists(filePath, function (exists) {
            if (exists) {
                var cmdStr = 'sh ' + filePath;
                exec(cmdStr, function(err, stdout, stderr) {
                    if (err) {
                        console.log(err);
                    } else {
                        fs.unlink(filePath, function (err) {
                            if (err) {
                                return console.log(err);
                            }
                            console.log('delete success ' + filePath + ' Output: ' + stdout);
                        });
                    }
                });
            }
        });
    }
});

