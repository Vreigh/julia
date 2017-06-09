using Gadfly
using DataArrays
using DataFrames

@everywhere function iterPoint(z; c=2, maxiter=200)
    for i=1:maxiter
        if abs(z) > 2
            return i-1
        end
        z = z^2 + c
    end
    maxiter
end

@everywhere function mapIter(julia_set, x, xrange, yrange, height, maxiter)
  for y=1:height
    z = xrange[x] + 1im*yrange[y]
    julia_set[x, y] = iterPoint(z, c=-0.70176-0.3842im, maxiter=maxiter)
  end
end

@everywhere function callIter!(julia_set, xrange, yrange, irange, jrange, maxiter)
  for x in irange, y in jrange
    z = xrange[x] + 1im*yrange[y]
    julia_set[x, y] = iterPoint(z, c=-0.70176-0.3842im, maxiter=maxiter)
  end
end

@everywhere function myrange(julia_set::SharedArray, q::SharedArray)
    idx = indexpids(q)
    if idx == 0
        return 1:0, 1:0
    end
    nchunks = length(procs(q))

    splits = [round(Int, s) for s in linspace(0,size(julia_set,2),nchunks+1)]
    1:size(julia_set,1), splits[idx]+1:splits[idx+1]
end

function fillPointsSequence!(julia_set, xrange, yrange; maxiter=200, height=400, width_start=1, width_end=400)
   for x=width_start:width_end
        for y=1:height
            z = xrange[x] + 1im*yrange[y]
            julia_set[x, y] = iterPoint(z, c=-0.70176-0.3842im, maxiter=maxiter)
        end
    end
end

function fillPointsParallel!(julia_set, xrange, yrange; maxiter=200, height=400, width_start=1, width_end=400)
  @sync @parallel for x=width_start:width_end
       for y=1:height
           z = xrange[x] + 1im*yrange[y]
           julia_set[x, y] = iterPoint(z, c=-0.70176-0.3842im, maxiter=maxiter)
       end
  end
end

function fillPointsPmap!(julia_set, xrange, yrange; maxiter=200, height=400, width_start=1, width_end=400)
  oneDim=collect(width_start:width_end)
  pmap(l->mapIter(julia_set, l, xrange, yrange, height, maxiter), oneDim) # dla kazdego x-a uzupelnij odpowiednia kolumne y
end

#  definiujemy obliczenie kernela z wyliczonym podziałem przez funkcje myrange()
@everywhere advection_shared_chunk!(q, julia_set, xrange, yrange, maxiter) = callIter!(julia_set, xrange, yrange, myrange(julia_set, q)..., maxiter)

function fillPointsHandy!(q, julia_set, xrange, yrange; maxiter=200)
  @sync begin
      for p in q
        @async remotecall_wait(advection_shared_chunk!, p, q, julia_set, xrange, yrange, maxiter)
      end
  end
end

function compareDrawJulia(h,w)
   xmin, xmax = -2,2
   ymin, ymax = -1,1
   xrange = linspace(xmin, xmax, w)
   yrange = linspace(ymin, ymax, h)
   julia_set = SharedArray(Int64, (w, h))

   df = DataFrame();
   df[:kinds] = 1:4
   df[:times] = DataArray(Float64, 4)
   q = SharedArray(Int,nprocs())
   for i=1:nprocs()
     q[i]=(procs()[i])
   end

   t = time()
   fillPointsSequence!(julia_set, xrange, yrange, height=h, width_end=w)
   df[:times][1] = time() - t

   t = time()
   fillPointsParallel!(julia_set, xrange, yrange, height=h, width_end=w)
   df[:times][2] = time() - t

   t = time()
   fillPointsPmap!(julia_set, xrange, yrange, height=h, width_end=w)
   df[:times][3] = time() - t

   t = time()
   fillPointsHandy!(q, julia_set, xrange, yrange)
   df[:times][4] = time() - t
   #Plots.heatmap(xrange, yrange, julia_set); png("pmap")

   l = layer(df, x="kinds", y="times", Geom.point)
   allplot = plot(l, Guide.XLabel("kinds"), Guide.YLabel("times"))
   draw(PNG("four.png", 4inch, 2inch), allplot)

   println(df)

end


function synPrint()
  l1 = ReentrantLock()
  cur = 1
  for i = 1:3
    @async begin
      j = 50
      for j = 1:50
        esc = false
        while true
          lock(l1)
          if cur == i
            print(i)
            cur = cur + 1
            if cur > 3 cur = 1 end
            esc = true
          end
          unlock(l1)
          yield()
          if esc break end
        end
      end
    end
  end
end
