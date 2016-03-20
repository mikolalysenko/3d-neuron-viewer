'use strict'

var shell = require('gl-now')({ tickRate: 1 })
var ndarray = require('ndarray')
var camera = require('game-shell-orbit-camera')(shell)
var mat4 = require('gl-mat4')
var binaryXHR = require('binary-xhr')
var createVolumeRenderer = require('./lib/viewer.js')

camera.lookAt([0, 0, -5], [0, 0, 0], [0, -1, 0])
var viewer

function loadVoxels (url) {
  binaryXHR(url, function (err, data) {
    viewer = createVolumeRenderer(shell.gl,
      ndarray(new Uint8Array(data), [300, 230, 230]))
  })
}

loadVoxels('example/neurons.bin')

shell.on('gl-render', function () {
  if (viewer) {
    viewer.projection = mat4.perspective(
      new Float32Array(16),
      Math.PI / 4.0,
      shell.width / shell.height,
      0.1,
      1000.0)
    viewer.view = camera.view()
    viewer.draw()
  }
})
