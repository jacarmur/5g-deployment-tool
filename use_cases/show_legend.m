function [] = show_legend(map)
    map.remove(map.LegendID);
    composite = globe.internal.CompositeModel;
    legend_colors = ["#ff0000", "#00b4ff", "#ffcc00", "#8dff41", "#ffffff"];
    legend_color_values = ["UMa", "UMi Coverage", "UMi Hotspot", "UMi Blind spot", "Receiver"];
    legend_title = 'Base Station Legend';
    legend_viewer = globe.internal.LegendViewer;
    legend_id = 'legendcolors';
    [~, legend_descriptor] = legend_viewer.buildPlotDescriptors(legend_title, legend_colors, legend_color_values, "ID", legend_id);
    map.LegendID = legend_id;
    composite.addGraphic("colorLegend", legend_descriptor);
    composite_controller = globe.internal.CompositeController(map.Instance.GlobeViewer.Controller);
    composite_controller.composite(composite.buildPlotDescriptors)
end

