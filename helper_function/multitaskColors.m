function [colors] = multitaskColors(inStr)
colors = zeros(1,3);
switch inStr

    case 's1a1'
        colors = [ 63, 116, 164] / 255;

    case 's2a2'
        colors = [78, 190, 223] / 255;

    case 's3a1'
        colors =  [100, 159, 106] / 255;

    case 's4a2'
        colors = [ 165, 212, 85] / 255;


end 

end
