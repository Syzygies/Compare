# Tarjan union-find algorithm for cycle counting

mutable struct Tarjan
    root::Vector{Int}
    sets::Int
end

function create(::Type{Tarjan}, n::Int)
    Tarjan(collect(0:n-1), n)
end

function reset!(t::Tarjan, n::Int)
    @inbounds for i in 0:n-1
        t.root[i+1] = i
    end
    t.sets = n
end

function find(t::Tarjan, a::Int)
    here = a

    @inbounds while t.root[here+1] != here
        here = t.root[here+1]
    end

    top = here
    here = a

    @inbounds while t.root[here+1] != top
        next = t.root[here+1]
        t.root[here+1] = top
        here = next
    end

    top
end

function unite!(t::Tarjan, a::Int, b::Int)
    a = find(t, a)
    b = find(t, b)

    if a != b
        t.sets -= 1
        @inbounds t.root[a+1] = b
    end
end

function set_count(t::Tarjan)
    t.sets
end

function name(::Type{Tarjan})
    "Tarjan"
end
