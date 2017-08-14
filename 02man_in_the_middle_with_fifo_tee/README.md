# A Quick summary of the FIFO / netcat command

The while loop keeps the command going until interrupted.

```
while true; do
cat /tmp/fifo | nc -l -p 1234 | tee -a to.log | nc machine port | tee -a from.log > /tmp/fifo`
done
```

^ stream `/tmp/fifo` - this sets up the socket to manipulate (input and output) - send it's input STDOUT

                   ^ nc process that stdin listening on localhost:1234 then send it to STDOUT

                                    ^ append all input to `to.log` and send it over to STDOUT

                                                   ^nc sends that input to `nc` host `machine` port `port`, resulting comm output goes to STDOUT

                                                                     ^append STDIN to `from.log` and send to STDOUT

                                                                                          ^redirect to `/tmp/fifo` (this completes the circuit, start at beginning)
