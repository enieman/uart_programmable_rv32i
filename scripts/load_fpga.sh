#!/usr/bin/env bash

dfu-util -R -a 0 -D "../fpga/bitstream.bin"
