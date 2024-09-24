function mmddyy = fn_yyyymmdd2mmddyy(yyyymmdd)

tempYear = floor(yyyymmdd/10000); tempDate = yyyymmdd - tempYear*10000; 
tempYear = tempYear-2000;
mmddyy = tempDate*100 + tempYear;

end 