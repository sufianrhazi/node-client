
{spawn} = require 'child_process'
stream = require './stream'
log = require './log'
{E} = require './err'

##=======================================================================

class Engine

  constructor : ({@args, @stdin, @stdout, @stderr}) ->

    # XXX make this configurable
    @name = "gpg"

    @stderr or= new stream.FnOutStream(log.warn)
    @stdin or= new stream.NullInStream()
    @stdout or= new stream.NullOutStream()

    @_exit_code = null
    @_exit_cb = null

  run : () ->
    @proc = spawn @name, @args
    @stdin.pipe @proc.stdin
    @proc.stdout.pipe @stdout
    @proc.stderr.on('data', (data) => 
      console.log "YYY " + data.toString()
      @stderr.write data
    )
    @pid = @proc.pid
    @proc.on 'exit', (status) => @_got_exit status
    @

  _got_exit : (status) ->
    @_exit_code = status
    @proc = null
    if (ecb = @_exit_cb)?
      @_exit_cb = null
      ecb status
    @pid = -1

  wait : (cb) ->
    if @_exit_code then cb @_exit_code
    else @_exit_cb = cb

##=======================================================================

bufferify = (x) ->
  if not x? then null
  else if (typeof x is 'string') then new Buffer x, 'utf8'
  else if (Buffer.isBuffer x) then x
  else null

##=======================================================================

exports.gpg = gpg = ({args, stdin, stdout, stderr, quiet}, cb) ->
  if (b = bufferify stdin)?
    stdin = new stream.BufferInStream b
  if quiet
    stderr = new stream.NullOutStream()
  if not stdout?
    def_out = true
    stdout = new stream.BufferOutStream()
  else
    def_out = false
  err = null
  await (new Engine { args, stdin, stdout, stderr }).run().wait defer rc
  if rc isnt 0
    err = new E.GpgError "exit code #{rc}"
    err.rc = rc
  out = if def_out? then stdout.data() else null
  cb err, out

##=======================================================================
