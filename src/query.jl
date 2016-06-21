################################################# FILE DESCRIPTION #########################################################

# This file contains methods, macros and operators aimed at providing the user a convenient UI to the graph datastructures 
# over the REPL.
 
################################################# IMPORT/EXPORT ############################################################

export 
# Filtering
vertex_filter, edge_filter
################################################# BASICS ###################################################################

# Getindex for basics
Base.getindex(g::Graph, ::Colon) = map(v->encode(g, v), vertices(g))
Base.getindex(g::Graph, ::Colon, ::Colon) = map(e->Pair(encode(g, e.first), encode(g, e.second)), edges(g))

# Getindex for vertex properties
Base.getindex(g::Graph, label) = getvprop(g, resolve(g, label))

# Getindex of edge properties
Base.getindex(g::Graph, e::Pair) = geteprop(g, resolve(g, e)...)

# Getindex for adjacencies
Base.getindex(g::Graph, label, ::Colon) = map(v->encode(g, v), fadj(g, resolve(g, label)))
Base.getindex(g::Graph, ::Colon, label) = map(v->encode(g, v), badj(g, resolve(g, label)))

# Getindex for subgraph
Base.getindex(g::Graph, vlist::Vector{VertexID}) = map(v->encode(g, v), vlist)
Base.getindex(g::Graph, elist::Vector{Pair{Int,Int}}) = map(e->Pair(encode(g, e.first), encode(g, e.second)), elist)

# Setindex for vertex properties
Base.setindex!(g::Graph, val, label, propname) = setvprop!(g, resolve(g, label), propname, val)

# Setindex for edge properties
Base.setindex!(g::Graph, val, e::Pair, propname) = seteprop!(g, resolve(g, e)..., propname, val)


################################################# FILTERING #################################################################

function Base.filter(g::Graph, vts::ASCIIString...)
   vlist = vertices(g)
   elist = collect(edges(g))

   for ts in vts
      if ismatch(r"v[.](\w+)", ts)
         # Vertex filter query
         vlist = vertex_filter(g, ts, vlist)
      elseif ismatch(r"e[.](\w+)", ts)
         # Edge filter query
         elist = edge_filter(g, ts, elist)
      else
         error("The input string couldn't be parsed. Please consult documentation")
      end
   end

   if(length(elist) == ne(g))
      return subgraph(g, vlist)
   elseif(length(vlist) == nv(g))
      return subgraph(g, elist)
   else
      return subgraph(subgraph(g, elist), vlist)
   end
end

function vertex_filter(g::Graph, ts::ASCIIString, vlist=vertices(g))
   fn = parse_vertex_query(ts)
   filter(v->fn(g, v), vlist)
end

function edge_filter(g::Graph, ts::ASCIIString, elist=collect(edges(g)))
   fn = parse_edge_query(ts)
   filter(e->fn(g, e...), elist)
end

# VertexFilter Query parsing
function parse_vertex_query(ts::ASCIIString)
   ts = strip(ts)

   # Relational filtering on vertex property
   rvpf = r"^v[.](\w+)\s*(<|>|<=|>=|!=|==)\s*(\w+)$"
   ismatch(rvpf, ts) && return rvpf_filter(match(rvpf, ts))

   error("The input string couldn't be parsed. Please consult documentation")
end

function rvpf_filter(m)
   prop = join(m[1])
   op = parse(m[2])
   val = isnumber(m[3]) ? parse(m[3]) : join(m[3])

   return (g,v) -> begin
      cmp = getvprop(g, v, prop)
      return cmp == nothing ? false : eval(op)(cmp, val)
   end
end


# EdgeFilter Query parsing
function parse_edge_query(ts::ASCIIString)
   ts = strip(ts)
   # Relational filtering on edge property
   repf = r"^e[.](\w+)\s*(<|>|<=|>=|!=|==)\s*(\w+)$"
   ismatch(repf, ts) && return repf_filter(match(repf, ts))

   error("The input string couldn't be parsed. Please consult documentation")
end

function repf_filter(m)
   prop = join(m[1])
   op = parse(m[2])
   val = isnumber(m[3]) ? parse(m[3]) : join(m[3])

   return (g, u, v) -> begin
      cmp = geteprop(g, u, v, prop)
      return cmp == nothing ? false : eval(op)(cmp, val)
   end
end