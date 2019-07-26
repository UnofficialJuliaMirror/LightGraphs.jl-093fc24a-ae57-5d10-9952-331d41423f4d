using LightGraphs:AbstractPathState, DijkstraState, BellmanFordState, FloydWarshallState
import Base:convert, getproperty
import LightGraphs: enumerate_paths

struct LGEnvironment
    threaded::Bool
    parallel::Bool
    LGEnvironment() = new(false, false)
end
     
abstract type AbstractGraphResults end
abstract type ShortestPathResults <: AbstractGraphResults end
abstract type AbstractGraphAlgorithm end
abstract type ShortestPathAlgorithm <: AbstractGraphAlgorithm end

##################
##   Dijkstra   ##
##################
struct DijkstraShortestPathResults{T<:Real, U<:Integer}  <: ShortestPathResults
    parents::Vector{U}
    dists::Vector{T}
    predecessors::Vector{Vector{U}}
    pathcounts::Vector{UInt64}
    closest_vertices::Vector{U}
end

convert(::Type{AbstractPathState}, spr::DijkstraShortestPathResults) = convert(DijkstraState, spr)
convert(::Type{<:DijkstraShortestPathResults}, s::DijkstraState) =
    DijkstraShortestPathResults(s.parents, s.dists, s.predecessors, s.pathcounts, s.closest_vertices)

convert(::Type{<:DijkstraState}, spr::DijkstraShortestPathResults) =
    DijkstraState(spr.parents, spr.dists, spr.predecessors, spr.pathcounts, spr.closest_vertices)

# These constructors do not copy. They probably should, but you shouldn't be changing the values in any case.
# Can we just document that it's undefined behavior to change any element of a SPR?
DijkstraShortestPathResults(s::DijkstraState) = convert(DijkstraShortestPathResults, s)
DijkstraState(spr::DijkstraShortestPathResults) = convert(DijkstraState, spr)

struct DijkstraShortestPathAlgorithm <: ShortestPathAlgorithm
    all_paths::Bool
    track_vertices::Bool

    DijkstraShortestPathAlgorithm() = new(false, false)
end


##################
##    A-Star    ##
##################
struct AStarShortestPathResults{E<:AbstractEdge} <: ShortestPathResults
    path::Vector{E}
end
# for completeness and consistency.
struct AStarState{E<:AbstractEdge} <: AbstractPathState
    path::Vector{E}
end

function enumerate_paths(s::AStarState)
    T = eltype(eltype(s.path))
    n = length(s.path)
    n == 0 && return Vector{T}()
    p = Vector{T}(undef, n+1)
    p[1] = src(s.path[1])
    p[end] = dst(s.path[end])
    for i in 2:n
        p[i] = src(s.path[i])
    end
    return p
end

convert(::Type{AbstractPathState}, spr::AStarShortestPathResults) = convert(AStarState, spr)
convert(::Type{<:AStarShortestPathResults}, s::AStarState) = AStarShortestPathResults(s.path)

convert(::Type{<:AStarState}, spr::AStarShortestPathResults) = AStarState(spr.path)

struct AStarShortestPathAlgorithm{F<:Function} <: ShortestPathAlgorithm
    heuristic::F
end
AStarShortestPathResults(s::AStarState) = convert(AStarShortestPathResults, s)
AStarState(spr::AStarShortestPathResults) = convert(AStarState, spr)

AStarShortestPathAlgorithm(T::Type{<:Real}=Float64) = AStarShortestPathAlgorithm(n -> zero(T))


##################
## Bellman-Ford ##
##################
struct BellmanFordShortestPathAlgorithm <: ShortestPathAlgorithm end
struct BellmanFordShortestPathResults{T<:Real, U<:Integer} <: ShortestPathResults
    parents::Vector{U}
    dists::Vector{T}
end

convert(::Type{AbstractPathState}, spr::BellmanFordShortestPathResults) = convert(BellmanFordState, spr)
convert(::Type{<:BellmanFordShortestPathResults}, s::BellmanFordState) =
    BellmanFordShortestPathResults(s.parents, s.dists)

convert(::Type{<:BellmanFordState}, spr::BellmanFordShortestPathResults) =
    BellmanFordState(spr.parents, spr.dists)



BellmanFordShortestPathResults(s::BellmanFordState) = convert(BellmanFordShortestPathResults, s)
BellmanFordState(spr::BellmanFordShortestPathResults) = convert(BellmanFordState, spr)



##################
##Floyd-Warshall##
##################

struct FloydWarshallShortestPathAlgorithm <: ShortestPathAlgorithm end
struct FloydWarshallShortestPathResults{T<:Real, U<:Integer} <: ShortestPathResults
    parents::Matrix{U}
    dists::Matrix{T}
end

convert(::Type{AbstractPathState}, spr::FloydWarshallShortestPathResults) = convert(FloydWarshallState, spr)
convert(::Type{<:FloydWarshallShortestPathResults}, s::FloydWarshallState) =
    FloydWarshallShortestPathResults(s.parents, s.dists)
convert(::Type{<:FloydWarshallState}, spr::FloydWarshallShortestPathResults) = 
    FloydWarshallState(spr.dists, spr.parents) # note - FWState is reversed from the others. Yuck.

FloydWarshallShortestPathResults(s::FloydWarshallState) = convert(FloydWarshallShortestPathResults, s)
FloydWarshallState(spr::FloydWarshallShortestPathResults) = convert(FloydWarshallState, spr)


# if we don't pass in distances, use weights.
shortest_paths(g::AbstractGraph, ss::Vector{T}, alg::ShortestPathAlgorithm) where {T<:Integer} =
    shortest_paths(g, ss, weights(g), alg)

# for A*, if we don't pass in distances...
shortest_paths(g::AbstractGraph, s::Integer, t::Integer, alg::AStarShortestPathAlgorithm) =
    shortest_paths(g, s, t, weights(g), alg)

# If we don't specify an algorithm, use dijkstra.
shortest_paths(g::AbstractGraph, s::Vector{T}, distmx::AbstractMatrix=weights(g)) where {T<:Integer} =
shortest_paths(g, s, distmx, DijkstraShortestPathAlgorithm())

# If we don't specify an algorithm and source is a scalar.
shortest_paths(g::AbstractGraph, s::Integer, distmx::AbstractMatrix=weights(g)) =
    shortest_paths(g, [s], distmx)

shortest_paths(g::AbstractGraph, s::Integer, alg::ShortestPathAlgorithm) = 
    shortest_paths(g, [s], alg)

# If we don't specify an algorithm AND there's no source, use Floyd-Warshall.
shortest_paths(g::AbstractGraph, distmx::AbstractMatrix=weights(g)) =
    shortest_paths(g, distmx, FloydWarshallShortestPathAlgorithm())

# Full-formed methods.
shortest_paths(g::AbstractGraph, ss, distmx, alg::DijkstraShortestPathAlgorithm) =
    DijkstraShortestPathResults(dijkstra_shortest_paths(g, ss, distmx, allpaths=alg.all_paths, trackvertices=alg.track_vertices))
    
shortest_paths(g::AbstractGraph, ss, distmx, alg::BellmanFordShortestPathAlgorithm) =
    BellmanFordShortestPathResults(bellman_ford_shortest_paths(g, ss, distmx))

shortest_paths(g::AbstractGraph, s::Integer, t::Integer, distmx, alg::AStarShortestPathAlgorithm{F}) where {F<:Function} =
    AStarShortestPathResults(a_star(g, s, t, distmx, alg.heuristic))

shortest_paths(g::AbstractGraph, distmx, alg::FloydWarshallShortestPathAlgorithm) =
    FloydWarshallShortestPathResults(floyd_warshall_shortest_paths(g, distmx))

enumerate_paths(s::ShortestPathResults) = enumerate_paths(convert(AbstractPathState, s))
    
#
# We might not want this.
# function getproperty(spr::ShortestPathResults, sym::Symbol)
#    if sym === :paths
#        return enumerate_paths(convert(AbstractPathState, spr))
#    else # fallback to getfield
#        return getfield(spr, sym)
#    end
# end
