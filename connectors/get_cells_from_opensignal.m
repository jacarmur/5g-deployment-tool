function [phone_cells] = get_cells_from_opensignal(bbox_cells)
    radio_value = 'LTE';
    key_value = '687c2037356ba7';
    format_value = 'json';
    cells_uri = 'http://opencellid.org/cell/getInArea';
    phone_cells = webread(cells_uri, 'key', key_value, 'radio', radio_value, 'format', format_value, 'BBOX', bbox_cells);
end

