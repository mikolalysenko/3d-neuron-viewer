'use strict'

var shell = require('gl-now')({ tickRate: 1, stopPropagation: false, preventDefault: false })
var ndarray = require('ndarray')
var camera = require('game-shell-orbit-camera')(shell)
var mat4 = require('gl-mat4')
var binaryXHR = require('binary-xhr')
var createVolumeRenderer = require('./lib/viewer.js')
var control = require('control-panel')

var viewer
var panel = control([
  {type: 'range', label: 'transparency', min: 0, max: 20, initial: 10},
  {type: 'range', label: 'intensity', min: 0, max: 10, initial: 4},
  {type: 'range', label: 'step', min: 1, max: 3, initial: 1}
],
  {theme: 'light', position: 'top-right'}
)

document.querySelector('.control-panel').style['z-index'] = 100

var state = { transparency: 10, intensity: 4, step: 1}
panel.on('input', function (data) {
  state = data
})

camera.lookAt([0, 0, -5], [0, 0, 0], [0, -1, 0])

function loadVoxels (url) {
  binaryXHR(url, function (err, data) {
    viewer = createVolumeRenderer(shell.gl,
      ndarray(new Uint8Array(data), [300, 230, 230]))
  })
}

loadVoxels('example/neurons.bin')

shell.on('gl-render', function () {
  if (viewer) {
    viewer.transparency = state.transparency
    viewer.intensity = state.intensity
    viewer.step = state.step
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
