function [] = show_legend(map)
map.remove(map.LegendID);
composite = globe.internal.CompositeModel;
legendColors = ["#ff0000", "#00b4ff", "#ffcc00", "#8dff41", "#ffffff"];
legendColorValues = ["UMa", "UMi Coverage", "UMi Hotspot", "UMi Blind spot", "Receiver"];
legendTitle = 'Base Station Legend';
lv = globe.internal.LegendViewer;
legendID = 'legendcolors';
[~, legendDescriptor] = lv.buildPlotDescriptors(legendTitle, legendColors, legendColorValues, "ID", legendID);
map.LegendID = legendID;
composite.addGraphic("colorLegend", legendDescriptor);
compositeController = globe.internal.CompositeController(map.Instance.GlobeViewer.Controller);
compositeController.composite(composite.buildPlotDescriptors)
end

