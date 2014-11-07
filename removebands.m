function remvertbands(sImg, nAmp, nStd, nWidthAdjust, nFixOffset)
% Load a NanoZoomer image and remove vertical bands
%
% Usage:
%   removebands(F, A, S, W, O)
%
% where
%   F is the filename of the image to process
%   A is the normalization amplitude (pixel intensity)
%   S is the detection limit (standard deviations)
%   W is a manual offset of automatically detected band intervals (pixels)
%   O is a manual horizontal offset of the normalization vector (pixels)
%
% Examples:
%   removebands('myimage.jpeg', 25, 3, -3, -1)
%
% Per Knutsen <pmknutsen@gmail.com> 08/29/2014
%

nVerbose = 1;

% Check that image exists
if ~exist(sImg, 'file')
    error(sprintf('The file %s cannot be found.', sImg))
    return
end

% Load Image
mImg = imread(sImg);
if nVerbose
    imtool(mImg)
end

% Assume bands appear in all three dimensions
mAvgImg = mean(mImg, 3); % average colors
vAvgCols = mean(mAvgImg, 1); % average columns

% Band pass average intensity to find band resets
a = 1 / 10;
xfilt = filtfilt([1-a a-1], [1 a-1], vAvgCols); % high pass
a = 1 / 50;
xfilt = filter(a, [1 a-1], xfilt); % low pass
nThresh = std(xfilt) * nStd;
iThresh = xfilt > nThresh;

if nVerbose
    hFig = figure;
    hAx = subplot(2, 1, 1, 'parent', hFig);
    hold(hAx, 'on')
    plot(hAx, xfilt)
    plot(hAx,[1 length(xfilt)], [nThresh nThresh], 'r--')
    plot(hAx,1:length(xfilt), iThresh.*nThresh, 'g-')
    xlabel(hAx,'Pixels')
    ylabel(hAx,'Average bandpass intensity (columns)')
    title(hAx, 'Bandpass and detection')
end

% Now get threshold crossins
iThresh = find(diff(iThresh) == 1);

if nVerbose
    plot(hAx, iThresh, repmat(nThresh, 1, length(iThresh)), 'rx', 'markersize', 10)
end

% Band width
nBandWidth = round(median(diff(iThresh))) + nWidthAdjust;

% Expand series to image boundaries
nBands = 100;
vBandOnsets = repmat(iThresh(1), 1, nBands+1) - (nBandWidth .* (0:nBands));
vBandOnsets = [vBandOnsets repmat(iThresh(end), 1, nBands+1) + (nBandWidth .* (0:nBands))];
vBandOnsets(vBandOnsets < 1 | vBandOnsets > length(vAvgCols)) = [];
iThresh = sort(unique([iThresh vBandOnsets]));

% Band start
if nVerbose
    hAx = subplot(2, 1, 2, 'parent', hFig);
    hold(hAx, 'on')
    plot(hAx, vAvgCols)
    plot(hAx, iThresh, vAvgCols(iThresh), 'rx', 'markersize', 10)
    
    xlabel(hAx,'Pixels')
    ylabel(hAx,'Average intensity (columns)')
    title(hAx, 'Band locations')
end

% Create filter mask
vX = 1:nBandWidth;
vY = (vX ./ nBandWidth) .* nAmp;

% tile in x to create normalization array
vNorm = repmat(vY, 1, length(iThresh)*2);

% offset normalization array
nStart = max([1 nBandWidth - iThresh(1) + 1 + nFixOffset]);
nEnd = nStart + size(vAvgCols, 2) - 1;

if nVerbose
    plot(hAx, vNorm(nStart:nEnd), 'g-')
end

% Create normalization matrix
% Each row is offset by +/1 n pixels as band boundary estimates may be
% inaccurate (i.e. introducting some deliberate fuzziness)
mNormImg = zeros(size(mAvgImg, 1), nEnd - nStart + 1);
nMaxOffset = 2; % user variable
for i = 1:size(mAvgImg, 1)
    nOffset = round((rand(1)-0.5) * (nMaxOffset*2));
    nOffset = max([1 nStart + nOffset]);
    mNormImg(i, :) = vNorm((nStart:nEnd) + repmat(nOffset, 1, length(nStart:nEnd)));
end

% Iterate over rows of image and subtract normalization array
% Slower, but maybe better than taking risk of out-of-memory errors
mNormImg = uint8(mNormImg);
for c = 1:3
    mImg(:, :, c) = mImg(:, :, c) - mNormImg;
end

if nVerbose
    imtool(mImg)
end

% Save processed image
[sDir sFile sExt] = fileparts(sImg);
sOutFile = fullfile(sDir, [sFile '_normalized' sExt]);
imwrite(mImg, sOutFile);

return
 

