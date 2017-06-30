package main

import (
	"os"
	"os/exec"
)

// Executes a command then returns true for success, false if there was an error, err is either nil or the error.
func execCmd(cmdExecName string, args []string, workingDir string) (success bool, err error) {
	cmd := exec.Command(cmdExecName, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Dir = workingDir
	err = cmd.Run()
	success = (err == nil)
	return
}
