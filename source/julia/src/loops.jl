# Loops algorithm for cycle counting

mutable struct Loops
    ends::Vector{Int}
    sets::Int
end

function create(::Type{Loops}, n::Int)
    Loops(collect(0:n-1), 0)
end

function reset!(t::Loops, n::Int)
    @inbounds for i in 0:n-1
        t.ends[i+1] = i
    end
    t.sets = 0
end

function unite!(t::Loops, a::Int, b::Int)
    @inbounds begin
        ea = t.ends[a+1]
        eb = t.ends[b+1]

        if ea == b
            t.sets += 1
        else
            t.ends[ea+1] = eb
            t.ends[eb+1] = ea
        end
    end
end

function set_count(t::Loops)
    t.sets
end

function name(::Type{Loops})
    "Loops"
end
