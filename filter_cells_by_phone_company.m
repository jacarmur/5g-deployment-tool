function [selected_phone_cells] = filter_cells_by_phone_company(phone_cells, company_index)

selected_phone_mnc_index = vertcat(phone_cells.cells.mnc) == company_index;
selected_phone_cells = phone_cells.cells(selected_phone_mnc_index);

end

