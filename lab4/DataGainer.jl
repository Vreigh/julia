using DataArrays
using DataFrames
using DifferentialEquations
using Gadfly
using Query

lv = @ode_def LotkaVolterra begin
  dx = a*x - b*x*y
  dy = -c*y + d*x*y
end  a => 1. b => 1. c => 1. d=> 1.

function getSingleData(A::Float64, B::Float64, C::Float64, D::Float64, ux::Float64, uy::Float64, id::String)
  const t = 10.0
  tspan = (0.0, t)

  lv = LotkaVolterra()
  lv.a = A
  lv.b = B
  lv.c = C
  lv.d = D

  u0 = [ux, uy]

  prob = ODEProblem(lv,u0,tspan)
  sol = solve(prob, RK4(), dt=0.01)

  df = DataFrame(t=sol.t, x=map(x->x[1],sol.u), y=map(x->x[2], sol.u), experiment=map(x->id, sol.u))

  return df
end

function printAvarages(dff::DataFrame)
  avg = DataFrame()

  dfPreyMin::DataFrame = by(dff, :experiment, df -> minimum(df[:x]))
  avg[:names] = dfPreyMin[1]
  avg[:preyMin] = dfPreyMin[2]

  dfPreyMax::DataFrame = by(dff, :experiment, df -> maximum(df[:x]))
  avg[:preyMax] = dfPreyMax[2]

  dfPreyMean::DataFrame = by(dff, :experiment, df -> mean(df[:x]))
  avg[:preyMean] = dfPreyMean[2]

  dfPredatorMin::DataFrame = by(dff, :experiment, df -> minimum(df[:y]))
  avg[:predatorMin] = dfPredatorMin[2]

  dfPredatorMax::DataFrame = by(dff, :experiment, df -> maximum(df[:y]))
  avg[:predatorMax] = dfPredatorMax[2]

  dfPredatorMean::DataFrame = by(dff, :experiment, df -> mean(df[:y]))
  avg[:predatorMean] = dfPredatorMean[2]

  print(avg)
end

function generateSeries()
  df1 = getSingleData(1., 1., 1., 1., 1., 1., "one")
  df2 = getSingleData(1., 2., 3., 1.5, 1., 1., "two")
  df3 = getSingleData(2., 2.5, 1., 0.5, 1., 1., "three")
  df4 = getSingleData(1.5, 1., 0.5, 0.75, 1., 1., "four")

  dfr = [df1; df2; df3; df4]
  dif = DataFrame(dif=[dfr[:2][x]-dfr[:3][x] for x in 1:length(dfr[:1])])
  dfr = [dfr dif]

  printAvarages(dfr)
  return dfr
end

function generateSingleCSV(A::Float64, B::Float64, C::Float64, D::Float64, ux::Float64, uy::Float64, id::String, fname::String)
  df = getSingleData(A, B, C, D, ux, uy, id)
  writetable(fname, df)
end

function generateSingleCSV(df::DataFrame, fname::String)
  writetable(fname, df)
end

function drawStacks()
  params = [[1., 1., 1., 1., 1., 1.], [1., 2., 3., 1.5, 1., 1.],
  [2., 2.5, 1., 0.5, 1., 1.], [1.5, 1., 0.5, 0.75, 1., 1.]]

  p = [] #plots
  l = [] #layers

  for i = 1 : length(params)
    df::DataFrame = getSingleData(params[i][1], params[i][2], params[i][3],
    params[i][4],params[i][5], params[i][6], string("exp", i))

    push!(l, layer(df, x="x", y="y", Geom.point))

    plotTitle = string("exp",i,"\na=",params[i][1],", b=",params[i][2],", c=", params[i][3],", d=", params[i][4])

    pl = plot(df, x = "x", y="y", Guide.XLabel("preys"), Guide.YLabel("predators"),Guide.Title(plotTitle))
    push!(p, pl)
  end

  #multiple plots
  myplot = gridstack([p[1] p[2]; p[3] p[4]])
  draw(PNG("myplot.png", 6inch, 8inch), myplot)

  allplot = plot(l[1], l[2], l[3], l[4], Guide.XLabel("preys"), Guide.YLabel("predators"))
  draw(PNG("stacks.png", 6inch, 8inch), allplot)

end
