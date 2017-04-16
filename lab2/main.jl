module ProfTest

function profile_test(n)
    for i = 1:n
        A = randn(100,100,20)
        m = maximum(A)
        Afft = fft(A)
        Am = mapslices(sum, A, 2)
        B = A[:,:,5]
        Bsort = mapslices(sort, B, 1)
        b = rand(100)
        C = B.*b
    end
end

function manipulate(a::Int)
  a += 20
  a -= 10
  a *= 3
  a /= 2
  return a
end

function slowOne()
  tab::Array{Int, 1} = [n for n = 1:50000]
  map(manipulate, tab)
end

function fastOne()
  tab::Array{Int, 1} = [n for n = 1:5000]
  map(manipulate, tab)
end

function test()
  for i = 1:500
    slowOne()
    fastOne()
  end
end

end
