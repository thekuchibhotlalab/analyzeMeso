function [colors] = multitaskColors(inStr)
colors = zeros(1,3);
switch inStr

    case 's1a1'
        colors = [90, 155, 211] / 255;

    case 's2a2'
        colors = [63, 116, 164] / 255;

    case 's3a1'
        colors =  [139, 203, 143] / 255;

    case 's4a2'
        colors = [100, 159, 106] / 255;


end 

end
