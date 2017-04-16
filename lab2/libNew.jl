module Graphs1

using StatsBase

export GraphVertex, NodeType, Person, Address,
       generate_random_graph, get_random_person, get_random_address, generate_random_nodes,
       convert_to_graph,
       bfs, check_euler, partition,
       graph_to_str, node_to_str,
       test_graph


abstract NodeType

type Person <: NodeType
  name::String
end

type Address <: NodeType
  streetNumber::Int
end

type GraphVertex
  value::NodeType
  neighbors::Array{GraphVertex, 1}
end

# Number of graph nodes.
const N = 800

# Number of graph edges.
const K = 10000

function generate_random_graph()
    A = Array{Int64,2}(N::Int, N::Int)

    for i=1:N::Int, j=1:N
      A[i,j] = 0
    end

    for i in sample(1:N*N, K::Int, replace=false)
      A[i] = 1
    end
    return A
end

# Generates random person object (with random name).
function get_random_person()
  return Person(randstring())
end

# Generates random person object (with random name).
function get_random_address()
  return Address(rand(1:100))
end

# Generates N random nodes (of random NodeType).
function generate_random_nodes()
  #nodes = Vector{NodeType}()
  nodes = Array{NodeType, 1}()
  for i= 1:N::Int
    push!(nodes, rand() > 0.5 ? get_random_person() : get_random_address())
  end
  return nodes
end


#= Converts given adjacency matrix (NxN)
  into list of graph vertices (of type GraphVertex and length N). =#
function convert_to_graph(A::Array{Int,2}, nodes::Vector{NodeType})
  graph = Array{GraphVertex, 1}()
  N::Int = length(nodes)
  for i = 1:N
    push!(graph, GraphVertex(nodes[i], GraphVertex[]))
  end
  #push!(graph, map(n -> GraphVertex(n, GraphVertex[]), nodes)...)
  for i = 1:N, j = 1:N
      if A[i,j] == 1
        push!(graph[i].neighbors, graph[j])
      end
  end
  return graph
end

#= Groups graph nodes into connected parts. E.g. if entire graph is connected,
  result list will contain only one part with all nodes. =#
function partition(graph::Array{GraphVertex, 1})
  parts = []
  remaining = Set(graph)
  visited = bfs(remaining)
  push!(parts, Set(visited))

  while !isempty(remaining)
    new_visited = bfs(remaining, visited)
    push!(parts, new_visited)
  end
  parts
end

#= Performs BFS traversal on the graph and returns list of visited nodes.
  Optionally, BFS can initialized with set of skipped and remaining nodes.
  Start nodes is taken from the set of remaining elements. =#

function bfs(remaining, visited=Set())
  return realBfs(visited, remaining)
end

function bfs(graph::Array{GraphVertex, 1})
  visited = Set()
  remaining = Set(graph)
  return realBfs(visited, remaining)
end

function realBfs(visited, remaining)
  first = next(remaining, start(remaining))[1]
  q = [first]
  push!(visited, first)
  delete!(remaining, first)
  local_visited = Set([first])

  while !isempty(q)
    v = pop!(q)

    for n in v.neighbors
      if !(n in visited)
        push!(q, n)
        push!(visited, n)
        push!(local_visited, n)
        delete!(remaining, n)
      end
    end
  end
  return local_visited
end

#= Checks if there's Euler cycle in the graph by investigating
   connectivity condition and evaluating if every vertex has even degree =#
function check_euler(graph::Array{GraphVertex, 1}) #usuniety niestabilny typ
  if length(partition(graph)) == 1
    if all(map(v -> iseven(length(v.neighbors)), graph))
      return 2
    else
      return 1
    end
  end
  return 0
end

#= Returns text representation of the graph consisiting of each node's value
   text and number of its neighbors. =#

function prepareName(p::Person)
  return "Person: $(p.name)\n"
end
function prepareName(a::Address)
  return "Street nr: $(a.streetNumber)\n"
end

function graph_to_str(graph::Array{GraphVertex, 1})
  graph_str = ""
  for v in graph
    graph_str *= "****\n"

    node_str = prepareName(v.value)
    graph_str *= node_str
    graph_str *= "Neighbors: $(length(v.neighbors))\n"
  end
  graph_str
end

#= Tests graph functions by creating 100 graphs, checking Euler cycle
  and creating text representation. =#
function test_graph()
  for i=1:100

    A = generate_random_graph()
    nodes = generate_random_nodes()
    graph::Array{GraphVertex, 1} = convert_to_graph(A, nodes)

    str = graph_to_str(graph)
    # println(str)
    tmp::Int = check_euler(graph)
    if tmp == 2
      println("true")
    elseif tmp == 1
      println("false")
    else
      println("Graph not connected!")
    end
  end
end

end
