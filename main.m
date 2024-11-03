clear                   % Clear the workspace
close all               % Close all figure windows
clc                     % Clear the command window

%% Reading File and Generating Bit Stream
disp('Reading input data.....');
data_file = 'image.png'; % Specify the input data file
disp('Done');
disp('Converting to Binary bit stream.....');

% Check if the file is an image (PNG or JPG)
if sum(data_file(end-2:end) == 'png') == 3 || sum(data_file(end-2:end) == 'jpg') == 3
    image = imread(data_file);         % Read the image file
    image = imresize(image, [128, 128]); % Resize the image to 128x128 pixels

    % Extract RGB channels and reshape each into a 1D array
    data = reshape(image(:, :, 1), 1, []);
    data = [data, reshape(image(:, :, 2), 1, [])];
    data = [data, reshape(image(:, :, 3), 1, [])];

    % Convert each byte (8 bits) to binary and reshape into 1D binary stream
    binary = reshape((dec2bin(data, 8))', [], 1);
    binary = reshape(str2num(binary), 1, []);
    bit_stream = [1 0 1 0 1 0 1 0, binary]; % Add header to identify it as an image

% Check if the file is a text file
elseif sum(data_file(end-2:end) == 'txt') == 3
    text = fileread(data_file);             % Read the text file
    binary = reshape(dec2bin(text, 8).' - '0', 1, []); % Convert text to binary
    bit_stream = [1 0 0 0 0 0 0 0, binary]; % Add header to identify it as text

% Check if the file is an audio file
elseif sum(data_file(end-2:end) == 'mp3') == 3
    [audio, Fs] = audioread(data_file);     % Read the audio file
    data = audio(:, 1);                     % Extract first audio channel
    data = ([data; audio(:, 2)])';          % Concatenate with second channel

    % Normalize data, convert to 8-bit range, and then to binary
    data = data - min(data);                
    data = round(255 * data / max(data));
    binary = reshape((dec2bin(data, 8))', [], 1);
    binary = reshape(str2num(binary), 1, []);
    Fs_binary = reshape((dec2bin(Fs, 16))', [], 1); % Convert sampling rate to binary
    Fs_binary = reshape(str2num(Fs_binary), 1, []);
    bit_stream = [1 1 1 1 1 1 1 1, Fs_binary, binary]; % Add header to identify it as audio
end
disp('Done');

%% Convolutional Coding
disp('Encoding with error correction coding.....');
trellis = poly2trellis(3, [6 7]);           % Define trellis structure for convolutional encoding
coded_bit_stream = convenc(bit_stream, trellis); % Apply convolutional encoding
disp('Done');

%% Block Coding (optional, commented out)
% disp('Encoding with error correction coding.....');
% coded_bit_stream = encode(bit_stream, 7, 4, 'hamming/binary'); % Optional Hamming code
% disp('Done');

%% Modulation (QAM)
disp('Modulating.....');
M = 16;                                      % Modulation order for 16-QAM
mod = qammod(coded_bit_stream, M);           % Map bits to QAM symbols
tx_data = mod;                               % Assign to transmission data variable
disp('Done');

%% OFDM with Multipath Rayleigh Fading
disp('tx in Multipath Rayleigh Fading using OFDM.....');
EbN0dB = 5;                                  % Set desired Eb/N0 (SNR per bit in dB)

%% OFDM Parameters (IEEE Specification)
N = 64;                                      % FFT size (number of subcarriers)
Nsd = 52;                                    % Number of data subcarriers
OFDM_BW = 40 * 10^6;                         % OFDM bandwidth

%% Derived Parameters
deltaF = OFDM_BW / N;                        % Subcarrier spacing
Tfft = 1 / deltaF;                           % FFT period (symbol duration without cyclic prefix)
Tgi = Tfft / 4;                              % Guard interval (cyclic prefix duration)
Tsignal = Tgi + Tfft;                        % Total OFDM symbol duration
Ncp = N * Tgi / Tfft;                        % Length of cyclic prefix in symbols
Nst = Nsd;                                   % Total number of used subcarriers
nBitsPerSym = Nst;                           % Bits per OFDM symbol for BPSK

% Adjust SNR to symbol level
EsN0dB = EbN0dB + 10 * log10(Nst / N) + 10 * log10(N / (Ncp + N)); 

errors = zeros(1, length(EsN0dB));           % Initialize error array

% Monte Carlo Simulation (optional, commented out)
% for i = 1:length(EsN0dB)
%     b = round(rand(1, nBitsPerSym * No_of_symbols)); % Random bit generation
b = tx_data;                                 % Assign transmitted data to bit sequence
No_of_symbols = length(b) / nBitsPerSym;     % Calculate number of symbols

% Reshape symbols for OFDM processing
s_r = reshape(s, nBitsPerSym, No_of_symbols).';

% Assign subcarriers and add nulls in IFFT input
X_k = [zeros(No_of_symbols, 1) s_r(:, [1:Nst / 2]) zeros(No_of_symbols, 11) s_r(:, [Nst / 2 + 1:end])];

% IFFT for OFDM modulation
xt = (N / sqrt(Nst)) * ifft(fftshift(X_k.')).'; 

% Adding Cyclic Prefix
xt = [xt(:, [N - Ncp + 1:N]) xt];            % Prepend cyclic prefix

% Multipath Fading Channel Model
nTap = 2;                                    % Set number of taps for multipath
ht = 1 / sqrt(2) * 1 / sqrt(nTap) * (randn(No_of_symbols, nTap) + j * randn(No_of_symbols, nTap)); % Generate complex Gaussian taps

for j_new = 1:No_of_symbols
    xht(j_new, :) = conv(ht(j_new, :), xt(j_new, :)); % Convolve signal with channel response
end

symbol_length = length(N - Ncp + 1:N) + N;   % Calculate symbol length including prefix

xt = xht;                                    % Assign convolved signal to transmission signal
xt = reshape(xt.', 1, No_of_symbols * (symbol_length + nTap - 1)); % Reshape to 1D for transmission

% Add Gaussian noise
nt = 1 / sqrt(2) * (randn(1, No_of_symbols * (symbol_length + nTap - 1)) + j * randn(1, No_of_symbols * (symbol_length + nTap - 1)));
yt = xt + 10^(-EsN0dB / 10) * nt;            % Add noise to transmitted signal

yt = reshape(yt.', symbol_length + nTap - 1, No_of_symbols).';
yt = yt(:, Ncp + 1:(N + Ncp));               % Remove cyclic prefix

yF = (sqrt(Nst) / N) * fftshift(fft(yt.')).';% Apply FFT to transform back to frequency domain

yF = yF ./ hF;                               % Equalize the received signal

R_Freq = yF(:, [(2:Nst / 2 + 1) (Nst / 2 + 13:Nst + 12)]); % Extract data subcarriers

rx_data = R_Freq;                            % Assign received data to variable
disp('Done');

%% Demodulation
disp('Demodulating.....');
bit_received = qamdemod(rx_data, M);         % Demodulate received data using QAM
bit_received = bit_received.';               % Transpose for linear bit stream
bit_received = bit_received(:).';            % Reshape to 1D array
disp('Done');

%% Viterbi Decoding
disp('Decoding for error correction coding.....');
tb = 4;                                      % Set traceback depth for Viterbi decoder
decoded_bit_stream = vitdec(bit_received, trellis, tb, 'trunc', 'soft', (M) - 1); % Apply Viterbi decoding
disp('Done');

%% Data Presentation
disp('Generating output from the binary bit stream.....');
check_type = decoded_bit_stream(1:8);        % Extract header to identify data type

if sum(check_type) < 3                       % Check if data is text
    file = decoded_bit_stream(9:end);        % Extract text content
    str = char(bin2dec(reshape(char(file + '0'), 8, []).')); % Convert binary to characters
    str = str';
    disp('It is a text and the content is:');
    disp(str);                               % Display the text content

elseif sum(check_type) < 7                   % Check if data is image
    file = decoded_bit_stream(9:end);        % Extract image data
    file = char(file + '0');                 % Convert to character array
    binaryVector = reshape(file, 8, []).';   % Reshape into 8-bit binary numbers
    decValues = bin2dec(binaryVector);       % Convert binary to decimal values
    decValues = reshape(decValues, 128, 128, 3); % Reshape to image dimensions
    disp('It is an image');
    imshow(uint8(decValues));                % Display the image

else                                         % Otherwise, assume data is audio
    Fs = decoded_bit_stream(9:24);           % Extract sampling rate
    Fs = bin2dec(num2str(Fs));               % Convert to decimal
    file = decoded_bit_stream(25:end);       % Extract audio content
    file = char(file + '0');                 % Convert to character array
    binaryVector = reshape(file, 8, []).';   % Reshape into 8-bit binary numbers
    decValues = bin2dec(binaryVector);       % Convert binary to decimal values
    audio = reshape(decValues, [], 2);       % Reshape to two-channel audio
    audio = audio / 255;                     % Normalize audio data
    disp('It is an audio');
    sound(audio, Fs);                        % Play the audio

end

%% BER Calculation
disp('Calculating BER.....');
c = abs(data - decoded_bit_stream);          % Compare transmitted and received bits
errors = nnz(c);                             % Count number of bit errors
BER = errors / length(data);                 % Calculate Bit Error Rate
disp(BER);                                   % Display BER
disp('Done');
