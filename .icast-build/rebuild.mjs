import fs from 'node:fs/promises';
import path from 'node:path';
import {FileBlob,PresentationFile} from '@oai/artifact-tool';
import {applyPresentationChartFont} from 'file:///C:/Users/Papa%20Offei/.codex/plugins/cache/openai-primary-runtime/presentations/26.1013.11914/skills/presentations/container_tools/artifact_tool_utils.mjs';
process.on('uncaughtException',e=>{console.error(e.message,e.stack?.split('\n').filter(x=>x.includes('rebuild.mjs')).join('\n'));process.exit(1)});
const dir='.icast-build/rebuilt';await fs.mkdir(dir,{recursive:true});
const p=await PresentationFile.importPptx(await FileBlob.load('C:/Users/Papa Offei/Downloads/ICAST/ICAST2026_Presentation_Template_.pptx'));
const original=[...p.slides.items],cover=original[0],base=original[3],end=original[11];
for(const s of original)if(![cover,base,end].includes(s)){const l=JSON.parse(await(await s.export({format:'layout'})).text());p.delete(l.slide.id);}
const baseLayout=JSON.parse(await(await base.export({format:'layout'})).text());
for(const x of baseLayout.elements)if(x.name==='Text 1'&&x.position.top>110)p.delete(x.id);
const bodies=[base];for(let i=0;i<13;i++)bodies.push(base.duplicate());
const slides=[cover,...bodies,end];for(let i=0;i<slides.length;i++)slides[i].moveTo(i);
const navy='#0B2545',blue='#326A99',muted='#566377',ink='#29333F',light='#EAF1F7',bg='#FAFAFA';
function txt(s,name,value,x,y,w,h,size=28,opt={}){const q=s.shapes.add({geometry:'textbox',name,position:{left:x,top:y,width:w,height:h},fill:'none',line:{fill:'none',width:0}});q.text=value;q.text.style={fontFamily:'Roboto',fontSize:size,color:ink,...opt};return q;}
function title(s,value){const q=s.shapes.items.find(x=>x.name==='Text 1');q.text=value;q.position={left:65,top:4,width:1090,height:96};q.text.style={fontFamily:'Roboto',fontSize:46,color:'#FFFFFF',alignment:'left',verticalAlignment:'middle'};}
function note(s,value){s.speakerNotes.text=value+'\n\nSource: Chest_XRay_Retrieval_IEEE_Format.docx, supplied manuscript. Reference numbers follow the paper.';}
function tag(s,value){txt(s,'Evidence note',value,72,659,1136,42,21,{color:muted});}
function table(s,values,{x=72,y=165,w=1136,h=420,widths,header=1,size=25,highlight=-1}={}){const t=s.tables.add({rows:values.length,columns:values[0].length,left:x,top:y,width:w,height:h,columnWidths:widths,values});t.borders.assign({fill:'#D8E1EA',width:0.7});for(let r=0;r<values.length;r++)for(let c=0;c<values[r].length;c++){const cell=t.getCell(r,c);cell.fill=r<header?navy:r===highlight?light:'#FFFFFF';cell.text.style={fontFamily:'Roboto',fontSize:size,color:r<header?'#FFFFFF':ink,bold:r<header||r===highlight||c===0};}return t;}
function chart(s,cfg){const c=s.charts.add('bar',{chartFill:bg,plotAreaFill:bg,hasLegend:true,legend:{position:'bottom',textStyle:{fontSize:21,fill:ink}},barOptions:{direction:'column',grouping:'clustered',gapWidth:95},...cfg});applyPresentationChartFont(c,{fontFamily:'Roboto'});return c;}
for(let i=0;i<bodies.length;i++){const n=bodies[i].shapes.items.find(x=>x.name==='Slide Number');if(n)n.text=String(i+2);}
const coverSh=n=>cover.shapes.items.find(x=>x.name===n);
coverSh('Title').text='Chest X-Ray Image Retrieval\nUnder Declining Target-Pathology Prevalence';
coverSh('Title').position={left:100,top:199,width:1080,height:175};coverSh('Title').text.style={fontFamily:'Roboto',fontSize:48,color:'#FFFFFF',alignment:'center'};
coverSh('Authors').text='Presented by Ofei Obuobisah Bekoe';coverSh('Authors').position={left:100,top:398,width:1080,height:47};coverSh('Authors').text.style={fontFamily:'Roboto',fontSize:30,color:'#FFFFFF',alignment:'center'};
coverSh('Affiliation').text='Department of Computer Science & Engineering\nUniversity of Mines and Technology, Tarkwa, Ghana';coverSh('Affiliation').position={left:100,top:459,width:1080,height:68};coverSh('Affiliation').text.style={fontFamily:'Roboto',fontSize:23,color:'#FFFFFF',alignment:'center'};
coverSh('Paper details').text='';
note(cover,'Presenting on behalf of the study authors: Obed Appiah, Ezekiel Mensah Martey, Emmanuel Asante, Ernest Kwame Ampomah, Ofei Obuobisah Bekoe, Henry Cobbinah, Boateng Kwedwo Amponsah and Grace Tsomemanya Tulasi. Obed Appiah is affiliated with the University of Energy and Natural Resources, Ghana; the remaining authors are affiliated with the University of Mines and Technology, Ghana. The presenter identity and contact follow the supplied ICAST template. Introduce the distinction between gallery prevalence and training-set imbalance.');
// 2: the concrete retrieval problem
{
const s=slides[1];title(s,'When relevant cases become rare');
txt(s,'Question','How much retrieval quality do we lose\nwhen relevant cases become rarer?',72,151,1120,120,43,{bold:true,color:navy});
txt(s,'Context','The query stays the same. The gallery still contains 20,000 images.',72,291,1120,60,28);
txt(s,'Start count','1,000',72,393,430,90,76,{bold:true,color:navy});
txt(s,'Start label','Relevant cases at 5% prevalence',72,489,500,48,27);
txt(s,'End count','100',738,393,430,90,76,{bold:true,color:blue});
txt(s,'End label','Relevant cases at 0.5% prevalence',738,489,470,72,27);
tag(s,'A fixed-gallery benchmark can miss this tenfold reduction in relevant-case availability.');
note(s,'Content-based medical image retrieval returns reference images ranked by visual representation similarity. Potential uses include case-based education and second-opinion reference. The present experiment holds the fitted model, query set and total gallery size fixed. Only the selected target share decreases, with other pathology distractor quotas fixed and background filling the remaining positions. This is evaluation-time prevalence variation, not a change in training-data balance.');
}
// 3: gap and questions
{
const s=slides[2];title(s,'Research gap and study questions');
txt(s,'Prior heading','Prior retrieval evaluations',72,155,510,50,30,{bold:true,color:navy});
txt(s,'Prior explanation','Pretrained embeddings, rare diseases\nand imbalanced galleries already\nhave substantial literature.',72,222,515,132,29);
txt(s,'Protocol distinction','Changing examples per class in a\nbalanced index changes support\nwhile preserving relative prevalence.',72,395,515,144,29);
txt(s,'Questions heading','This controlled experiment',682,155,526,50,30,{bold:true,color:navy});
txt(s,'Question one','1  How does declining target prevalence\n    affect retrieval across pathologies\n    and representation models?',682,222,526,149,29);
txt(s,'Question two','2  From the same SwAV initialization,\n    does contrastive adaptation improve\n    retrieval over classification?',682,408,526,149,29);
tag(s,'The comparison concerns six ResNet-50 conditions and three target pathologies.');
note(s,'The narrative review found no controlled multi-level reduction in target prevalence with query sets and fitted representations held fixed among the reviewed studies. This does not imply that scarcity has been ignored. Denner et al. [1] provide a close conceptual precedent but vary balanced index support, so their reported retrieval metrics are not numerically comparable. The study does not establish a universal ordering of supervised and self-supervised learning.');
}
// 4: source evidence, with only its redundant title cropped
{
const s=slides[3];title(s,'Data sources and experimental roles');
const b=await fs.readFile('.icast-build/image1.png');s.images.add({blob:b,contentType:'image/png',fit:'contain',crop:{left:0,top:.075,right:0,bottom:0},position:{left:58,top:119,width:1164,height:580},alt:'Original manuscript data-flow figure showing NIH, SIIM, common-class sources, deduplication, patient separation and the tuberculosis audit.'});
note(s,'Figure 1 from the supplied manuscript, with only the redundant figure title cropped. NIH ChestX-ray14 supplied multi-label adaptation data, cardiomegaly and emphysema queries, and retrieval-pool images after patient exclusions. SIIM supplied pneumothorax queries. External sources supplied normal, pneumonia and COVID-19 adaptation data. Target-positive NIH patients were excluded from adaptation and background partitions. NIH adaptation splits contained 48,280 training, 12,266 validation and 10,620 background images. The common-class dataset contained 4,545 images after source-class balancing, split 80:20. External metadata did not establish exhaustive finding labels or full patient identity. The tuberculosis audit excluded TB as an evaluated target, while retaining it as a fixed 2% distractor.');
}
// 5: controlled protocol, without a crowded diagram
{
const s=slides[4];title(s,'A fixed gallery with declining prevalence');
txt(s,'Fixed heading','What stays fixed',72,156,490,50,32,{bold:true,color:navy});
txt(s,'Fixed variables','200 queries per target pathology\n\n20,000 images per gallery\n\nThe fitted model and retrieval depth\n\n400 images per non-target pathology',72,228,518,290,28);
table(s,[['Target share','Relevant images'],['5%','1,000'],['2%','400'],['1%','200'],['0.5%','100']],{x:664,y:165,w:544,h:349,widths:[272,272],size:27});
txt(s,'Replication','3 targets × 4 prevalence levels × 5 gallery samples',72,566,1136,57,32,{bold:true,color:navy});
tag(s,'60 galleries. All six models use identical gallery manifests and fixed query sets.');
note(s,'Targets are cardiomegaly, emphysema and pneumothorax. Each gallery has the selected target count, 400 images from each of three non-target pathologies, and background images filling remaining positions. TB remains one distractor. Cardiomegaly and emphysema use at most one NIH query per patient and exclude query patients from NIH retrieval pools. Pneumothorax uses SIIM queries and an NIH relevant pool. Five gallery seeds resample image identities under source quotas. All fitted models use the same manifests. The five samples estimate gallery-sampling sensitivity, not training variability.');
}
// 6: make each model condition explicit
{
const s=slides[5];title(s,'Six representation conditions');
table(s,[['Condition','Initialization','Task-specific adaptation'],['CNN-PT','Supervised ImageNet','None'],['CNN-Common','CNN-PT','Normal / pneumonia / COVID-19 classification'],['CNN-NIH','CNN-PT','NIH multi-label classification'],['SwAV-PT','Self-supervised ImageNet','None'],['SwAV-CLS','SwAV-PT','Same NIH classification as CNN-NIH'],['SwAV-SupCon','SwAV-PT','Weighted multi-label contrastive learning']],{x:72,y:150,w:1136,h:449,widths:[220,320,596],size:24,highlight:6});
tag(s,'Shared ResNet-50 backbone. Target labels are absent from available fine-tuning annotations.');
note(s,'All conditions provide 2,048-dimensional global average-pooled embeddings after removing the classification layer. CNN-PT and SwAV-PT use ImageNet-pretrained representations without task adaptation. CNN-Common uses the balanced external common-class data. CNN-NIH, SwAV-CLS and SwAV-SupCon share NIH partitions. The SwAV checkpoint is the official 800-epoch ImageNet model. Held out and zero-shot refer to available fine-tuning labels, not verified clinical absence of target pathology in every image.');
}
// 7: objective and retrieval mechanics
{
const s=slides[6];title(s,'Adaptation and exact image retrieval');
txt(s,'Learning heading','Contrastive adaptation',72,157,530,52,31,{bold:true,color:navy});
txt(s,'Learning text','Two augmented views of each image\n\nPositive-pair weights follow the\noverlap of NIH label sets\n\nProjection head supports training\nand is removed for retrieval',72,231,530,303,28);
txt(s,'Retrieval heading','Retrieval for every condition',682,157,526,52,31,{bold:true,color:navy});
txt(s,'Retrieval text','1  Resize and normalize the image\n\n2  Extract a 2,048-D embedding\n\n3  Apply L2 normalization\n\n4  Rank the full gallery by cosine similarity',682,231,526,333,28);
tag(s,'AdamW, learning rate 0.0001. One fitted checkpoint per learned condition.');
note(s,'Training uses grayscale replicated over three channels and 224 × 224 resizing, ImageNet normalization, horizontal flips, rotation, crops and brightness/contrast jitter. Evaluation uses resizing and normalization only. AdamW learning rate and weight decay are 1e-4, cosine annealing over at most 50 epochs, and early stopping after at least ten epochs with patience seven. Classification uses 64 images per batch. SupCon uses 64 source images with two views, 128 views per step, a 2,048-2,048-128 projection head and temperature 0.07. Distinct-image positive weights are Jaccard overlaps of NIH label sets; the paired view of the same image has weight one. Objective-specific validation losses select checkpoints. Exact ranking uses normalized dot products, equivalent to cosine similarity. Query images are excluded. Training ran on two Tesla T4 GPUs with PyTorch 2.10.0+cu128.');
}
// 8: metrics and inference
{
const s=slides[7];title(s,'Retrieval metrics and statistical tests');
txt(s,'Precision label','Precision@10',72,162,510,50,34,{bold:true,color:navy});
txt(s,'Precision meaning','Relevant results among the first ten,\ndivided by ten.',72,229,530,91,30);
txt(s,'Ndcg label','nDCG@10',72,371,510,50,34,{bold:true,color:navy});
txt(s,'Ndcg meaning','Adds sensitivity to where relevant\nimages appear in the top ten.',72,438,530,91,30);
txt(s,'Inference label','Paired comparisons',682,162,526,50,34,{bold:true,color:navy});
txt(s,'Inference meaning','Average each query across five galleries.\n\nUse paired Wilcoxon tests and\nglobal Holm correction.\n\nBootstrap intervals describe uncertainty\nconditional on the observed galleries.',682,229,526,300,28);
tag(s,'Primary contrast: 5% versus 0.5%. Error bars across galleries do not measure retraining variability.');
note(s,'P@10 is the primary endpoint; nDCG@10 checks ranking position. Relevance is binary and label-based for the designated query pathology. Each gallery has at least 100 relevant images, so the ideal top ten are all relevant. Prevalence effects use Friedman tests and Kendall W, followed by the primary paired contrast. Holm families contain 18 prevalence contrasts per metric. Six planned model comparisons over three pathologies and four prevalence levels give 72 globally corrected comparisons. Unadjusted 95% percentile intervals use 10,000 paired query resamples and are not simultaneous intervals. Statistical significance follows adjusted p-values.');
}
// 9: all model-pathology endpoints, not a selectively chosen subset
{
const s=slides[8];title(s,'Every model loses precision');
const vals=[['Model','Cardiomegaly','','Emphysema','','Pneumothorax',''],['','5%','0.5%','5%','0.5%','5%','0.5%'],['CNN-PT','0.1078','0.0119','0.1669','0.0191','0.2578','0.0320'],['CNN-Common','0.1343','0.0109','0.1775','0.0194','0.3335','0.0484'],['CNN-NIH','0.1109','0.0116','0.1512','0.0198','0.3283','0.0545'],['SwAV-PT','0.1435','0.0157','0.1902','0.0249','0.3058','0.0421'],['SwAV-CLS','0.1259','0.0133','0.1686','0.0175','0.3287','0.0446'],['SwAV-SupCon','0.1597','0.0163','0.2377','0.0335','0.4140','0.0660']];
const t=table(s,vals,{x:72,y:147,w:1136,h:420,widths:[224,152,152,152,152,152,152],size:23,header:2,highlight:7});
t.merge({startRow:0,endRow:1,startColumn:0,endColumn:0});for(const c of [1,3,5])t.merge({startRow:0,endRow:0,startColumn:c,endColumn:c+1});
txt(s,'Loss value','83.4%–91.9%',72,587,440,65,44,{bold:true,color:navy});
txt(s,'Loss description','Relative P@10 reduction across all 18 pairs.\nEvery decline survives Holm correction.',536,588,672,73,26);
note(s,'All P@10 endpoint means are copied from manuscript Table 2. The highlighted SupCon row has the highest mean at both endpoints for each target and also ranks first at 1% and 2%. Relative reductions range from 83.4% to 91.9% across the 18 model-pathology combinations. Absolute reductions range from 0.0959 to 0.3480. All 18 primary endpoint contrasts are significant for both metrics after Holm correction, adjusted p ≤ 2.30 × 10^-26. nDCG absolute losses range from 0.0977 to 0.3694. Means summarize five gallery samples and one fitted checkpoint per learned condition.');
}
// 10: isolate the central adaptation comparison
{
const s=slides[9];title(s,'Contrastive versus classification adaptation');
txt(s,'Comparison setup','Same SwAV initialization, NIH partitions and ResNet-50 backbone',72,132,1136,46,27,{color:muted});
chart(s,{position:{left:57,top:193,width:796,height:425},categories:['Cardiomegaly','Emphysema','Pneumothorax'],series:[{name:'SwAV-CLS',values:[.0133,.0175,.0446],fill:'#AAB8C7'},{name:'SwAV-SupCon',values:[.0163,.0335,.0660],fill:navy}],yAxis:{min:0,max:.08,majorUnit:.02,numberFormatCode:'0.00',textStyle:{fontSize:20},majorGridlines:{fill:'#D8E1EA',width:.8},title:{text:'Precision@10 at 0.5% prevalence',textStyle:{fontSize:21}}},xAxis:{textStyle:{fontSize:19}},dataLabels:{showValue:true,position:'outEnd',numberFormatCode:'0.0000',textStyle:{fontSize:21,fill:ink}}});
txt(s,'Significant count','10/12',900,219,305,90,66,{bold:true,color:navy});
txt(s,'Significance statement','SupCon advantages\nsurvive global correction\nacross all prevalence levels.',900,325,305,180,27);
tag(s,'Exceptions: cardiomegaly at 0.5% and 1%. The chart shows the 0.5% endpoint.');
note(s,'SupCon has a higher mean than SwAV-CLS in every one of 12 pathology-prevalence conditions and exceeds it significantly in ten globally corrected planned comparisons. At 0.5%: cardiomegaly 0.0163 versus 0.0133, adjusted p > 0.99; emphysema 0.0335 versus 0.0175, adjusted p = 5.34e-7; pneumothorax 0.0660 versus 0.0446, adjusted p = 3.17e-6. The two cardiomegaly contrasts at 0.5% and 1% do not survive correction. This supports the contrastive adaptation finding in the evaluated design, not a universal superiority claim. Objective-specific checkpoint selection and different effective contrastive batch size limit isolation of the objective alone.');
}
// 11: distinguish enrichment from absolute quality
{
const s=slides[10];title(s,'Above random, with low absolute precision');
txt(s,'Setting','Leading model at 0.5% prevalence: SwAV-SupCon',72,139,1136,44,28,{color:muted});
const xs=[72,476,880],names=['Cardiomegaly','Emphysema','Pneumothorax'],en=['3.26×','6.70×','13.20×'],pr=['0.0163','0.0335','0.0660'];
for(let i=0;i<3;i++){txt(s,'Pathology '+i,names[i],xs[i],236,328,52,31,{bold:true,color:navy});txt(s,'Enrichment '+i,en[i],xs[i],318,328,96,64,{bold:true,color:blue});txt(s,'Enrichment label '+i,'Random-ranking enrichment',xs[i],423,328,62,24);txt(s,'Precision '+i,'Precision@10 = '+pr[i],xs[i],508,328,56,27);}
tag(s,'Random-ranking P@10 = 0.005. Enrichment alone does not establish clinical usefulness.');
note(s,'The three leading absolute means at 0.5% are 0.0163, 0.0335 and 0.0660. Dividing by 0.005 yields 3.26, 6.70 and 13.20 times random expectation. All evaluated model-pathology conditions remain above random at this endpoint. Enrichment increases between 5% and 0.5% in 17 of 18 combinations, but this is descriptive relative discrimination, not proof of adequate retrieval. The study does not measure diagnostic decisions or clinician workflow. Pneumothorax is a cross-source configuration and cannot be compared as a source-controlled estimate of pathology difficulty.');
}
// 12: the absolute-loss scale effect
{
const s=slides[11];title(s,'Absolute loss needs endpoint context');
txt(s,'Example','Pneumothorax example',72,135,1136,48,29,{color:muted});
chart(s,{position:{left:58,top:203,width:792,height:415},categories:['SwAV-CLS','SwAV-SupCon'],series:[{name:'5% prevalence',values:[.3287,.4140],fill:navy},{name:'0.5% prevalence',values:[.0446,.0660],fill:'#547FA9'}],yAxis:{min:0,max:.5,majorUnit:.1,numberFormatCode:'0.0',title:{text:'Precision@10',textStyle:{fontSize:22}},textStyle:{fontSize:20},majorGridlines:{fill:'#D8E1EA',width:.8}},xAxis:{textStyle:{fontSize:23}},dataLabels:{showValue:true,position:'outEnd',numberFormatCode:'0.0000',textStyle:{fontSize:22}}});
txt(s,'Loss heading','Absolute P@10 loss',900,218,310,47,27,{bold:true,color:navy});
txt(s,'Cls loss','SwAV-CLS\n0.2841',900,290,310,98,30);
txt(s,'Supcon loss','SwAV-SupCon\n0.3480',900,418,310,98,30,{bold:true,color:navy});
tag(s,'SupCon loses more in absolute terms while retaining higher precision at both endpoints.');
note(s,'The example illustrates the scale effect described in manuscript Section IV-C. SupCon P@10 decreases from 0.4140 to 0.0660, a 0.3480 loss. CLS decreases from 0.3287 to 0.0446, a 0.2841 loss. SupCon therefore loses 0.0639 more but remains higher at both endpoints. A larger absolute loss is not by itself evidence of worse rare-case retrieval. Assess endpoint quality and relative enrichment alongside loss. These are paired model means under the evaluated cross-source pneumothorax configuration.');
}
// 13: material limitations, including narrow zero-shot claim
{
const s=slides[12];title(s,'Limits on interpretation');
const rows=[['Training uncertainty','One fitted checkpoint per learned condition. Five gallery seeds do not estimate retraining variability.'],['Source confounding','SIIM supplies pneumothorax queries and NIH supplies relevant images. Source and retrieval role remain aligned.'],['Labels and zero-shot scope','Target labels are absent from available fine-tuning annotations. Unrecorded target findings may still be present.'],['Clinical relevance','Binary recorded labels define relevance. No radiologist evaluated clinical similarity or diagnostic benefit.']];
for(let i=0;i<rows.length;i++){const y=148+i*132;txt(s,'Limit heading '+i,rows[i][0],72,y,350,92,29,{bold:true,color:navy});txt(s,'Limit text '+i,rows[i][1],454,y,754,108,28);}
note(s,'All conditions use ResNet-50, limiting architecture generalization. Classification and SupCon checkpoints use objective-specific selection criteria. TB was excluded after a source-confounding audit, narrowing pathology coverage. No source-separability diagnostic was performed for pneumothorax. NIH labels are report-derived and noisy. External common-class labels are not exhaustive. SIIM metadata do not establish patient uniqueness. Horizontal flipping may affect laterality-dependent findings. The lowest prevalence still provides 100 relevant images, and much larger approximate indexes or lower absolute counts remain untested.');
}
// 14: conclusion follows directly from evidence
{
const s=slides[13];title(s,'Conclusions and next experiments');
txt(s,'Main conclusion','Gallery prevalence belongs in\nthe retrieval benchmark.',72,154,1136,121,44,{bold:true,color:navy});
txt(s,'Conclusion evidence','Precision and ranking quality decline across every evaluated\nmodel–pathology pair as the target share falls.',72,302,1136,95,30);
txt(s,'Adaptation conclusion','Contrastive adaptation leads in this study, with a significant\nadvantage over SwAV-CLS in 10 of 12 conditions.',72,420,1136,95,30);
txt(s,'Next work label','Next experiments',72,565,300,50,29,{bold:true,color:navy});
txt(s,'Next work text','Independent training runs, stronger source controls,\nlower relevant-case counts and clinician-assessed relevance.',413,563,795,95,27);
note(s,'The paper recommends reporting performance at at least two clinically relevant gallery-prevalence levels. The study shows substantial absolute degradation and pathology-dependent model separation. It supports the evaluated SupCon-versus-classification adaptation result but not an architecture-independent or universal learning-paradigm ordering. Future work should replicate training, broaden architectures, test lower relevant-case counts and improve clinical and source controls.');
}
// 15: readable abbreviated references, complete entries in notes
{
const s=slides[14];title(s,'Selected references');
const items=[['[1] Denner et al.','Leveraging foundation models for content-based image retrieval in radiology.\nComputers in Biology and Medicine, 2025.'],['[9] Wang et al.','ChestX-ray8: Hospital-scale chest X-ray database and benchmarks.\nCVPR, 2017.'],['[10] He et al.','Deep residual learning for image recognition.\nCVPR, 2016.'],['[11] Caron et al.','Unsupervised learning of visual features by contrasting cluster assignments.\nNeurIPS, 2020.'],['[12] Khosla et al.','Supervised contrastive learning.\nNeurIPS, 2020.']];
for(let i=0;i<items.length;i++){const y=147+i*108;txt(s,'Reference author '+i,items[i][0],72,y,270,80,25,{bold:true,color:navy});txt(s,'Reference title '+i,items[i][1],365,y,843,83,24);}
const full=(await fs.readFile('.icast-build/paper.txt','utf8')).split('\n').filter(x=>/^\[(1|9|10|11|12)\]/.test(x)).join('\n\n');note(s,'Selected entries use abbreviated display titles for readability. Full entries from the manuscript:\n\n'+full);
}
end.shapes.items.find(x=>x.name==='Contact').text='Ofei Obuobisah Bekoe\nce-pobekoe1423@st.umat.edu.gh\nUniversity of Mines and Technology, Ghana';
end.shapes.items.find(x=>x.name==='Contact').position={left:526,top:405,width:680,height:120};end.shapes.items.find(x=>x.name==='Contact').text.style={fontFamily:'Roboto',fontSize:23,color:muted};end.shapes.items.find(x=>x.name==='Slide Number').text='16';note(end,'Invite questions about prevalence-controlled evaluation, the choice of adaptation objective and cross-source design.');
await(await PresentationFile.exportPptx(p)).save(path.join(dir,'candidate.pptx'));console.log('EXPORTED',p.slides.items.length);
await fs.writeFile(path.join(dir,'presentation.json'),JSON.stringify(p.toProto()));
for(let i=0;i<p.slides.items.length;i++){const s=p.slides.items[i];await fs.writeFile(path.join(dir,`${i+1}.png`),new Uint8Array(await(await s.export({format:'png',scale:1})).arrayBuffer()));await fs.writeFile(path.join(dir,`${i+1}.json`),await(await s.export({format:'layout'})).text());console.log('RENDER',i+1);}
console.log('READY');
