import numpy as np
import networkx as nx
import csv
from pprint import pprint
import pygraphviz as pgv
import matplotlib.pyplot as plt
import os
from datetime import datetime
itr_count=0

n=5
output_directory="generate_transgraph/graph/"

for node_a in range(1,n):
    for node_b in range(1,n):
        for node_p in range(1,5):
            # while True:
            for edge_ap in range(np.max([node_a,node_p]), node_a*node_p):
                for edge_bp in range(np.max([node_b,node_p]), node_b*node_p):
                    print("a:"+str(node_a))
                    print("b:"+str(node_b))
                    print("p:"+str(node_p))

                    print("edge_ap:"+str(edge_ap))
                    print("edge_bp:"+str(edge_bp))

                    condition=  edge_ap>= node_a and edge_bp>= node_b and edge_ap>= node_p and edge_bp>= node_p #ノード数とエッジの関係
                    condition = condition and (node_a*node_p)>=edge_ap and (node_b*node_p)>=edge_bp #これ以上はる枝がない
                    if condition:
                        G=nx.DiGraph()

                        # ピボット作成
                        # for i in range(1,node_p+1):
                        for i in range(node_p):
                            G.add_node("p-"+str(i),lang='language_P',langP='1',langA='0',langB='0')
                            print("p-"+str(i))
                            if node_a>node_p:
                                G.add_edge("a-"+str(i),"p-"+str(i))
                            if node_b>node_p:
                                G.add_edge("p-"+str(i),"b-"+str(i))

                        #ノード作成
                        # for i in range(1,node_a+1):
                        for i in range(node_a):
                            G.add_node("a-"+str(i),lang='language_A',langA='1',langB='0')
                            print("a-"+str(i))
                            # A-Pノード
                            if node_p>node_a:
                                G.add_edge("a-"+str(i),"p-"+str(i))
                                print("hgoe")


                        # for i in range(1,node_b+1):
                        for i in range(node_b):
                            G.add_node("b-"+str(i),lang='language_B',langB='1',langA='0')
                            print("b-"+str(i))
                            # B-Pノード
                            if node_p>node_b:
                                G.add_edge("p-"+str(i),"b-"+str(i))
                                print("hgoe")

                        tmp=0
                        while True:
                            tmp+=1

                            # tmp_a=np.random.random_integers(node_a)
                            # tmp_p=np.random.random_integers(node_p)
                            # tmp_b=np.random.random_integers(node_b)
                            tmp_a=np.random.randint(node_a-1)
                            tmp_p=np.random.randint(node_p-1)
                            tmp_b=np.random.randint(node_b-1)

                            #AとP
                            for i in range(np.min([node_a,node_p]),edge_ap):
                            # for i in range(np.min([node_a,node_p]),np.max([node_a,node_p])):

                                if node_a > node_p: #P少ない
                                    G.add_edge("a-"+str(i),"p-"+str(tmp_p))
                                else: #A少ない
                                    # for i in range(np.min([node_a,node_p])+1,edge_ap+1):
                                    G.add_edge("a-"+str(tmp_a),"p-"+str(i))

                            #BとP
                            for i in range(np.min([node_b,node_p]),edge_bp):
                            # for i in range(np.min([node_b,node_p]),np.max([node_b,node_p])):
                                if node_b > node_p: #P少ない
                                    # for i in range(np.min([node_b,node_p])+1,edge_bp+1):
                                    G.add_edge("p-"+str(i),"b-"+str(tmp_b))
                                else: #B少ない
                                    # for i in range(np.min([node_b,node_p])+1,edge_bp+1):
                                    G.add_edge("p-"+str(tmp_p),"b-"+str(i))


                            # condition=nx.is_connected(G.to_undirected())
                            if tmp>50:
                                print("グラフ作成できず163")

                                break

                            # 任意のピボットと必ずAとBはつながる
                            # A,B,Pの個数確認
                            count_connected_component=0
                            condition=0
                            has_edge_pa=0
                            has_edge_pb=0
                            output_node_a=0
                            output_node_b=0
                            output_node_p=0
                            graphs = nx.connected_component_subgraphs(G.to_undirected())
                            #
                            for subgraph in graphs:
                                count_connected_component+=1
                                if count_connected_component==1:
                                    lang=nx.get_node_attributes(subgraph,'lang')
                                    langP=nx.get_node_attributes(subgraph,'langP')
                                    langA=nx.get_node_attributes(subgraph,'langA')
                                    langB=nx.get_node_attributes(subgraph,'langB')

                                    # if len(subgraph)==(node_a+node_b+node_p):
                                    for node in subgraph.nodes():
                                        pprint("node")
                                        pprint(node)
                                        # print(langA[node])
                                        # print(langB[node])

                                        # print(lang[node])
                                        # if lang[node]=='language_P':
                                        #     pprint(node)
                                        #     # has_edge_pa=0
                                        #     # has_edge_pb=0
                                        #     for node_a_b in subgraph.neighbors(node):
                                        #         if lang[node_a_b]=='language_A':
                                        #             has_edge_pa=1
                                        #         elif lang[node_a_b]=='language_B':
                                        #             has_edge_pb=1
                                        #             # else
                                                    #     has_edge_pb*=-1

                                else:
                                    print("一つのトランスグラフになってない")



                            # output_node_a=
                            # output_node_b=
                            # output_node_p=
                            if nx.is_connected(G.to_undirected()):# and has_edge_pa ==1 and has_edge_pb == 1:#and G.number_of_nodes()==(node_a+node_b+node_p) and G.number_of_edges()== (edge_ap+edge_bp):
                                itr_count += 1
                                print("祝作成")

                                g_visualize = nx.to_agraph(G)
                                # g_visualize.draw(output_directory+"graph/"+str(node_a)+str(node_p)+str(node_b)+str(edge_ap)+str(edge_bp)+str(itr_count)+'.pdf',prog='dot')
                                output_new_dir=str(node_a)+"-"+str(node_p)+"-"+str(node_b)
                                if not os.path.exists(output_directory+output_new_dir):
                                    os.makedirs(output_directory+output_new_dir)

                                output_file=str(node_a)+"-"+str(node_p)+"-"+str(node_b)+"-"+str(edge_ap)+"-"+str(edge_bp)+"-"+str(itr_count)+datetime(2014,1,2,3,4,5).strftime('%s')
                                g_visualize.draw(output_directory+output_new_dir+"/"+output_file+'.pdf',prog='dot')
                                # with open(output_directory+"csv/"+str(node_a)+str(node_p)+str(node_b)+str(edge_ap)+"-"+str(edge_bp)+str(itr_count)+".csv", "w") as file:
                                    # itr_count+=1
                                    # lang=nx.get_node_attributes(G,'lang') # <-この処理遅い
                                    # file.write("test")
                                # break
                            # else:
                                # tmp+=1
                                # break


                    else:
                        print("グラフ作成できず")
                        continue