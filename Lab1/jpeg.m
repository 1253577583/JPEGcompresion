I = imread('greylena.bmp');
figure;
imshow(I);title("原图");
Y_dsp = I;
[row, column] = size(Y_dsp);
Y_dct = zeros(size(Y_dsp));

Q = [16 11 10 16 24 40 51 61 ;
     12 12 14 19 26 28 60 55 ;
     14 13 16 24 40 57 69 56 ;
     14 17 22 29 51 87 80 62 ;
     18 22 37 56 68 109 103 77 ;
     24 35 55 64 81 104 113 92 ;
     49 64 78 87 103 121 120 101 ;
     72 92 95 98 112 100 103 99];

zigzag = [1 2 6 7 15 16 28 29;
     3 5 8 14 17 27 30 43;
     4 9 13 18 26 31 42 44;
     10 12 19 25 32 41 45 54;
     11 20 24 33 40 46 53 55;
     21 23 34 39 47 52 56 61;
     22 35 38 48 51 57 60 62;
     36 37 49 50 58 59 63 64];
%dct and quantization
for j = 1:8:row - 7
    for k = 1:8:column - 7
    Y_dct(j:j+7, k:k+7) = dct2(Y_dsp(j:j+7, k:k+7));
    Y_dct(j:j+7, k:k+7) = round(Y_dct(j:j+7, k:k+7) ./ Q);
    end
end
%show dct img
figure;
imshow(uint8(Y_dct));title("DCT变换 + 量化");

%random secret information
secret = zeros(1,10000);
for i = 1:10000
    if rand < 0.5 
        secret(i) = 0;
    else
        secret(i) = 1;
    end
end
index = 1;
[~ , col] = size(secret);
%f3 insert secret information
for m = 1:8:row - 7
    for n = 1:8:row - 7               
        for i = 0:7
            for j = 0:7
                if index > col
                    break;
                end
                if Y_dct(m+i,n+j)~=0
                    if mod(Y_dct(m+i,n+j) , 2) == secret(index) 
                        index = index + 1;                   
                    elseif mod(Y_dct(m+i,n+j) , 2) == 0 && secret(index) == 1
                        Y_dct(m+i,n+j) = ttg(Y_dct(m+i,n+j));
                        index = index + 1;                           
                    elseif Y_dct(m+i,n+j) == 1 || Y_dct(m+i,n+j) == -1
                        Y_dct(m+i,n+j) = 0;                   
                    else
                        Y_dct(m+i,n+j) = ttg(Y_dct(m+i,n+j));
                        index = index + 1;
                    end
                end
            end
        end                
    end
end
%zigzag line
inf = [];
for j = 1:8:row - 7
    for k = 1:8:row - 7
        Y_lin = zeros(1, 64);
        for i = 1:8
            Y_lin(zigzag(i, :)) = Y_dct(j+i-1, k:k+7);
        end
        inf = [inf , Y_lin];
    end
end
pinf = inf;
%Run Length Encoding
%Compression and decompression
inf = rle(inf , "en");
rinf = inf;
inf = rle(inf , "de");
if pinf == inf
    disp("compression success")
else
    disp("compression failed")
end
%zigzag line recovery
test_val = zeros(size(Y_dsp));
aBlock = zeros(8,8);
for j = 1:8:row - 7
    for k = 1:8:row - 7
        a_line = zeros(1,64);
        count = int32((j-1)/8)*64 + int32((k-1)/8);
        a_line = inf(1+64*count : 64+64*count);
        for m = 1:8
            for n = 1:8
                aBlock(m,n) = a_line(zigzag(m,n));
            end
        end
        test_val(j:j+7, k:k+7) = aBlock(1:8,1:8);
    end
end
if test_val == Y_dct
    disp("zigzag line recovery success")
else
    disp("zigzag line recovery failed")
end


Y_idct = zeros(size(Y_dsp));
for j = 1:8:row - 7
    for k = 1:8:column - 7
    Y_idct(j:j+7, k:k+7) = (test_val(j:j+7, k:k+7) .* Q);
    Y_idct(j:j+7, k:k+7) = round(idct2(Y_idct(j:j+7, k:k+7)));
    end
end

figure;
imshow(uint8(Y_idct));title("逆过程");

for j = 1:8:row - 7
    for k = 1:8:column - 7
    Y_dct(j:j+7, k:k+7) = dct2(Y_idct(j:j+7, k:k+7));
    Y_dct(j:j+7, k:k+7) = round(Y_dct(j:j+7, k:k+7) ./ Q);
    end
end

% figure;
% imshow(uint8(Y_dct));title("再次DCT变换 + 量化");

index = 1;
ans = zeros(1,10000);
for m = 1:8:row-7
    for n = 1:8:row-7       
        for i = 0:7
            for j = 0:7
                if index > col
                    break;
                end
                if Y_dct(m+i,n+j)~=0
                    ans(index) = mod(Y_dct(m+i,n+j) , 2);
                    index = index + 1;
                end
            end
        end                
    end
end

if secret == ans
    disp("insert success");
else
    disp("insert failed");
end