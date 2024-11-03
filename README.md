# Data-Transmission-Using-OFDM-through-Multipath-Rayleigh-Fading-Channel-in-MATLAB
In this project, we simulated a wireless data transmission system in MATLAB that can transmit text, audio and image data using Orthogonal Frequency Division Multiplexing (OFDM) through a multipath Rayleigh fading channel. For modulation, 16-QAM (Quadrature Amplitude Modulation) was used. Convolutional Coding was used for error correction coding and Viterbi algorithm was used for error correction decoding.

  * [Features](#features)
  * [Parameters](#parameters)
  * [Requirements](#requirements)
  * [Usage](#usage)
  * [Code Overview](#code-overview)
  * [Example](#example)


## Features

- **Input Data Types**: Supports image (`.png`, `.jpg`), text (`.txt`), and audio (`.mp3`) files.
- **Binary Conversion**: Converts input files into a binary bit stream with a header indicating file type.
- **Error Correction Coding**: Uses convolutional encoding for error correction, with optional block coding.
- **Modulation**: Modulates the bit stream using Quadrature Amplitude Modulation (QAM).
- **OFDM Transmission**: Simulates OFDM transmission with multipath Rayleigh fading.
- **Demodulation and Decoding**: Recovers the original bit stream using demodulation and Viterbi decoding.
- **Data Reconstruction**: Reconstructs the original file type (image, text, or audio) from the decoded bit stream.
- **BER Calculation**: Calculates and displays the Bit Error Rate (BER) to evaluate transmission accuracy.


## Parameters

### Input Parameters

- **data_file**: File name of the input data (`image.png`, `text.txt`, or `audio.mp3`).

### Encoding: Convolutional Coding

- **trellis**: Trellis structure for convolutional encoding, defined as `poly2trellis(3, [6 7])`.
- **M**: Modulation order for QAM (set to 16 for 16-QAM).

### OFDM Transmission

- **EbN0dB**: Signal-to-noise ratio per bit in decibels (dB) (default value: 5 dB).
- **N**: Number of subcarriers in OFDM (FFT size, set to 64).
- **Nsd**: Number of data subcarriers (set to 52).
- **OFDM_BW**: Bandwidth of the OFDM system (set to 40 MHz).
- **Tfft**: FFT period, derived from the subcarrier spacing.
- **Tgi**: Guard interval (cyclic prefix duration), set to 1/4 of the FFT period.
- **Tsignal**: Total OFDM symbol duration (FFT period plus guard interval).
- **Ncp**: Number of cyclic prefix samples.
- **Nst**: Total number of used subcarriers.
- **nBitsPerSym**: Number of bits per OFDM symbol, set to equal `Nst`.

### Channel Model: Multipath Rayleigh Fading Channel

- **nTap**: Number of taps for the multipath Rayleigh fading channel (set to 2).

### Decoding: Viterbi Algorithm

- **tb**: Traceback depth for Viterbi decoding (set to 4).

## Requirements

- MATLAB R2020b or newer
- Image Processing Toolbox (for image handling)
- Communications Toolbox (for modulation and coding)
- Signal Processing Toolbox (for audio handling)

## Usage

1. **Prepare an Input File**:
    - Place an input file (`image.png`, `text.txt`, or `audio.mp3`) in the same directory as the script.
2. **Run the Script**:
    - Execute the script `main.m` in MATLAB to process the input file, transmit it through an OFDM system, and reconstruct the output.
3. **Output**:
    - Based on the file type, the script displays the following:
        - **Image**: Displays the reconstructed image.
        - **Text**: Prints the text content in the MATLAB command window.
        - **Audio**: Plays the reconstructed audio.
    - Displays the Bit Error Rate (BER) to assess transmission accuracy.

## Code Overview

- **File Reading and Bit Stream Generation**:
    - Converts the input file to a binary bit stream with a type header.
- **Error Correction Coding**:
    - Encodes the bit stream using convolutional coding and optionally block coding for error resilience.
- **QAM Modulation**:
    - Modulates the encoded bit stream using 16-QAM.
- **OFDM Transmission**:
    - Simulates OFDM transmission with Rayleigh fading to test robustness in a multipath channel environment.
- **Demodulation and Decoding**:
    - Demodulates the received signal and applies Viterbi decoding to retrieve the original bit stream.
- **Output Reconstruction**:
    - Based on the header, reconstructs and displays the image, text, or audio.
- **BER Calculation**:
    - Calculates and outputs the Bit Error Rate to evaluate the effectiveness of transmission and error correction.

## Example
```matlab
% Specify input file name in the file "main.m"
data_file = 'image.png';

% Run the script to process, transmit, and reconstruct the file
% MATLAB will display or play the output and display the Bit Error Rate (BER)
```
