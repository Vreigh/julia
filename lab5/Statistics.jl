using DataArrays
using DataFrames
using Gadfly
using Query

function drawStatistics(df::DataFrame)
  l = layer(df, x="workes", y="times", Geom.point)
  allplot = plot(l, Guide.XLabel("workers"), Guide.YLabel("time"))
  draw(PNG("statistics.png", 6inch, 8inch), allplot)
end
