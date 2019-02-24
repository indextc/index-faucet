import { Apis } from 'indexjs-ws'
import {ChainStore, FetchChain, PrivateKey, PublicKey, TransactionHelper, Aes, TransactionBuilder} from "indextcjs"
import config from '../config/config.json'

wsString = config.nodeUrl
registrar = config.registrarAccount
registrarPrivateKey = config.registrarPrivateKey

Apis.setAutoReconnect true

Apis.instance(wsString, true).init_promise.then (res) ->
  console.log("connected to:", res[0].network)

Apis.register = (name, owner, active, memo) ->
  if not name.match(/[0-9-]/) or not name.match(/[aeiouy]/)
    throw new Error 'Premium names registration is not supported by this faucet'

  await ChainStore.init()

  pKey = PrivateKey.fromWif(registrarPrivateKey)

  Promise.all([
    FetchChain("getAccount", registrar)
    FetchChain("getAccount", name)
  ]).then (res) ->
    [registrar, newAccount] = res

    # console.log newAccount
    if newAccount
      throw new Error 'Account already exists'

    tr = new TransactionBuilder()

    tr.add_type_operation "account_create",
      fee:
        amount: 0
        asset_id: "1.3.0"
      registrar: registrar.get('id')
      referrer: registrar.get('id')
      referrer_percent: 0
      name: name
      owner:
        weight_threshold: 1
        account_auths: []
        key_auths: [[owner, 1]]
        address_auths: []
      active:
        weight_threshold: 1
        account_auths: []
        key_auths: [[active, 1]]
        address_auths: []
      options:
        memo_key: memo
        voting_account: '1.2.5'
        num_witness: 0
        num_committee: 0

    tr.set_required_fees().then ->
      tr.add_signer(pKey, pKey.toPublicKey().toPublicKeyString())
      console.log("serialized transaction:", tr.serialize())
      tr.broadcast()

export default Apis
