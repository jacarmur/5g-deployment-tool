function [selected_phone_cells] = filter_cells_by_phone_company(phone_cells, company_index)

selected_phone_mnc_index = vertcat(phone_cells.cells.mnc) == company_index; % Vodafone = 1; Orange = 3; Telefonica = 7 (ver MNC wikipedia)

%select the cells with the desired mnc
%selected_phone_cells = [];
index = 1;
for i = 1:phone_cells.count
    if selected_phone_mnc_index(i)
        selected_phone_cells(index) = phone_cells.cells(i);
        index = index+1;
    end
end
end

