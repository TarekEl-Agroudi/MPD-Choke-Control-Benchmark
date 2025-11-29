
function displayKPIs(Results, scenarioNames)
    disp([repmat('#',1,30), '  Key Performance Indicators  ', repmat('#',1,30)]);
    for k = 1:numel(Results)
        KPIFields = fieldnames(Results(k).KPI);
        KPIData   = [];
        KPIFieldsScalar = {};  % only keep scalar fields

        for f = 1:numel(KPIFields)
            val = Results(k).KPI.(KPIFields{f});
            if isscalar(val) && isnumeric(val)
                KPIData = [KPIData, val];
                KPIFieldsScalar{end+1} = KPIFields{f}; %#ok<AGROW>
            end
            % skip non-scalar KPIs
        end

        fprintf('\n============ %s ============\n\n', scenarioNames{Results(k).Scenario});
        T = array2table(KPIData, 'VariableNames', KPIFieldsScalar);
        disp(T);
    end
    disp(repmat('#',1,100));
end