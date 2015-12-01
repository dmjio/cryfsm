module Convert.LDAG.DOT (convert) where

import Data.Graph.Inductive.Graph (Graph, mkGraph)
import Data.Graph.Inductive.PatriciaTree (Gr)
import Data.GraphViz (GraphvizParams(fmtNode, fmtEdge), graphToDot, nonClusteredParams, printDotGraph, toLabel)
import Data.LDAG (LDAG(layers), Layer(nodes), LayerID, Node(Node, nodeLabel, outgoing))
import Data.Text.Lazy (Text)
import Data.Universe.Class (Finite, universeF)
import qualified Data.IntMap as IM

-- | (!) assumes that the nodes at different layers have different IDs
convert :: LDAG [Bool] Bool -> Text
convert = printDotGraph . graphToDot showParams . toFGLGr

toFGLGr :: Finite e => LDAG n e -> Gr (LayerID, n) e
toFGLGr = toFGL

toFGL :: (Graph gr, Finite e) => LDAG n e -> gr (LayerID, n) e
toFGL ldag = mkGraph ns es where
  ns = [ (nodeID, (layerID, nodeLabel node))
       | (layerID, layer) <- IM.assocs (layers ldag)
       , (nodeID, node)   <- IM.assocs (nodes layer)
       ]
  es = [ (fromNodeID, children edgeLabel, edgeLabel)
       | layer <- IM.elems (layers ldag)
       , (fromNodeID, Node { outgoing = Just children })
           <- IM.assocs (nodes layer)
       , edgeLabel <- universeF
       ]

showParams :: GraphvizParams n (LayerID, [Bool]) Bool () (LayerID, [Bool])
showParams = nonClusteredParams
  { fmtNode = \(_, (_, bs)) -> [toLabel . showBools $ bs]
  , fmtEdge = \(_, _, el)   -> [toLabel . showBool  $ el]
  }

showBools = concatMap showBool
showBool False = "0"
showBool True  = "1"