import express from 'express'
import bodyParser from 'body-parser'
import cors from 'cors'
import RateLimit from 'express-rate-limit'
import IndexApi from './api'
import Debug from debug

log = Debug 'faucet:app'

app = express()
app.use cors()
app.use bodyParser.json()
app.enable 'trust proxy'

createAccountLimiter = new RateLimit
  windowMs: 60*60*1000 # 1 hour window
  delayAfter: 1, # begin slowing down responses after the first request
  delayMs: 3*1000, # slow down subsequent responses by 3 seconds per request
  max: 1, # start blocking after 5 requests
  message: "Too many accounts created from this IP, please try again after an hour"

app.use (err, req, res, next) ->
  debug 'Unknown error', err.stack
  res.status(500).send('Something broke!')

app.use '/api/v1/accounts', createAccountLimiter
app.use '/api/v1/accounts', (req, res) ->
  console.log req.params, req.query, req.body
  { name, owner_key, active_key, memo_key } = req.body.account
  try
    await IndexApi.register name, owner_key, active_key, memo_key
  catch error
    return res.status(400).json({message: error.message})
  res.json {message: 'OK'}

app.use (req, res, next) ->
  res.status(404).send('Sorry cant find that!')

app.listen 3000, ->
  console.log 'Index Faucet listening on port 3000!'
