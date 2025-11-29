function assignAllVariables(  )
 list = evalin('caller','who');
    if ~isempty(list)
        for i = 1 : length(list)
           assignin('base',list{i}, evalin('caller',list{i}));
        end
    end
end

