    chai = require 'chai'
    chai.use require 'chai-as-promised'
    chai.should()
    Promise = require 'bluebird'

    describe 'The local module', ->
      local = require '../src/local'
      it 'should properly compute values', ->
        cfg = require './config.json'

        outcomes =
          33646: '95813_140_1250_0.2_0_0_0_1'
          7676: '76709_364_1426_0.3_0_0_0_0'
        checks = []
        for k,v of outcomes
          checks.push (local.get_billing_data cfg, k).should.eventually.equal v
        Promise.all checks

      it 'should report errors', ->
        cfg = require './config.json'
        tel = '00192'

        (local.get_billing_data cfg, tel).should.be.rejectedWith Error, /cannot GET \/_si\/prefix\/00192/
