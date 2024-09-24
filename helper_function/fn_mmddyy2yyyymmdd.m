function yyyymmdd = fn_mmddyy2yyyymmdd(mmddyy)
if mmddyy>1000000
    yyyymmdd = mmddyy;
else
    tempDate = floor(mmddyy/100); tempYear = mmddyy - tempDate*100; 
    tempYear = tempYear+2000;
    yyyymmdd = tempYear*10000 + tempDate;
end

end 