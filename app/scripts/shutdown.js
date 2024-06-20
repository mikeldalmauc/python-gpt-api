const { exec } = require('child_process');

// Specify the port your application uses
const port = 3000;

// Command to find the process ID (PID) using the specified port with netstat
const command = `netstat -lntp | grep :${port} | awk '{print $7}' | cut -d'/' -f1`;

exec(command, (error, stdout, stderr) => {
  if (error) {
    console.error(`Error executing command: ${error.message}`);
    return;
  }

  if (stderr) {
    console.error(`Error: ${stderr}`);
    return;
  }

  const pid = stdout.trim();
  if (pid) {
    console.log(`Killing process with PID: ${pid}`);
    exec(`kill -9 ${pid}`, (killError, killStdout, killStderr) => {
      if (killError) {
        console.error(`Error killing process: ${killError.message}`);
        return;
      }

      if (killStderr) {
        console.error(`Kill Error: ${killStderr}`);
        return;
      }

      console.log(`Process with PID ${pid} killed successfully`);
    });
  } else {
    console.log(`No process found on port ${port}`);
  }
});
