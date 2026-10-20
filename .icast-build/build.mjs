import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {FileBlob,PresentationFile} from '@oai/artifact-tool';
process.on('uncaughtException',e=>{console.error(e.message, e.stack?.split('\n').filter(x=>x.includes('build.mjs')).join('\n'));process.exit(1)});
const root=process.cwd(),build=path.join(root,'.icast-build'),src='C:/Users/Papa Offei/Downloads/ICAST/ICAST2026_Presentation_Template_.pptx';
const skill='C:/Users/Papa Offei/.codex/plugins/cache/openai-primary-runtime/presentations/26.1013.11914/skills/presentations';
const p=await PresentationFile.importPptx(await FileBlob.load(src));
const ss=p.slides.items;
function sh(i,name){return ss[i-1].shapes.items.find(x=>x.name===name)}
function set(i,name,text,size){const s=sh(i,name);s.text=text;if(size)s.text.style={fontFamily:'Roboto',fontSize:size};return s;}
function body(i,text){const s=ss[i-1].shapes.items.find(x=>x.name==='Text 1'&&x.position.top>110);s.text=text;return s;}
function title(i,text){const s=ss[i-1].shapes.items.find(x=>x.name==='Text 1');s.text=text;}
function note(i,text){ss[i-1].speakerNotes.text=text+'\n\nSource: Chest_XRay_Retrieval_IEEE_Format.docx, supplied manuscript. Reference numbers follow the manuscript.';}
set(1,'Authors','Obed Appiah, Ezekiel Mensah Martey, Emmanuel Asante, Ernest Kwame Ampomah,\nOfei Obuobisah Bekoe, Henry Cobbinah, Boateng Kwedwo Amponsah, Grace Tsomemanya Tulasi',21);
sh(1,'Authors').position={left:86,top:361,width:1108,height:69};
set(1,'Affiliation','University of Energy and Natural Resources, Ghana\nUniversity of Mines and Technology, Tarkwa, Ghana',20);
sh(1,'Affiliation').position={left:80,top:438,width:1120,height:54};
set(1,'Paper details','Presenter: Ofei Obuobisah Bekoe   ·   ce-pobekoe1423@st.umat.edu.gh',18);
sh(1,'Paper details').position={left:80,top:503,width:1120,height:30};
note(1,'This study asks how chest X-ray retrieval changes when relevant cases become rare in a fixed-size gallery. The author list follows the manuscript. Presenter and presenter contact follow the supplied conference template.');
set(2,'Outline item 1','Problem and prior work');set(2,'Outline item 2','Study objectives');set(2,'Outline item 3','Evaluation protocol');
note(2,'The talk covers the motivation and related work, study objectives, controlled evaluation protocol, findings, and limitations with future work.');
set(3,'Section title','The study question',55);
set(3,'Section summary','How does retrieval quality change\nwhen relevant cases become rarer?',29);
sh(3,'Section summary').position={left:526,top:375,width:680,height:104};
note(3,'The manipulated quantity is gallery prevalence: the proportion of gallery images carrying the target pathology. Gallery size, fitted model, query set, and retrieval depth remain fixed. This isolates prevalence at evaluation time rather than changing training-set balance.');
title(4,'Background and Research Gap');
body(4,'Image retrieval returns similar prior cases for education and reference.\nExisting work studies embeddings, rare diseases and imbalanced galleries.\nChanging examples per class in a balanced index preserves prevalence.\nThis study fixes gallery size and reduces the target share from 5% to 0.5%.');
note(4,'Related work motivates the protocol rather than providing directly comparable metric values. Denner et al. [1] compared representations and varied indexed support while keeping classes balanced. SISH [2] and volumetric retrieval [4] examine rare or imbalanced settings. The reviewed work did not isolate a controlled multi-level prevalence reduction while holding queries and representations fixed. This is a narrative, non-systematic review.');
set(5,'Card text 1','Measure retrieval loss as target prevalence decreases across three held-out pathologies.');
set(5,'Card text 2','Compare six ResNet-50 conditions with fixed queries, checkpoints and gallery size.');
set(5,'Card heading 3','Implication');
set(5,'Card text 3','Report retrieval at multiple prevalence levels, alongside absolute quality and enrichment.');
note(5,'The secondary question compares classification and supervised contrastive fine-tuning from the same SwAV initialization. Held out means the three target labels were absent from available fine-tuning annotations, not verified clinical absence in every training image.');
title(6,'Prevalence-Controlled Evaluation');
const l6=JSON.parse(await(await ss[5].export({format:'layout'})).text());
for(const x of l6.elements)if(x.editable!==false&&x.kind==='shape'&&x.position.top>110&&x.name!=='Slide Number')p.delete(x.id);
const b=await fs.readFile(path.join(build,'image2.png'));
ss[5].images.add({blob:b.buffer.slice(b.byteOffset,b.byteOffset+b.byteLength),contentType:'image/png',alt:'Original manuscript Figure 2 showing fixed 200-query sets, four prevalence levels and five gallery samples, with exact gallery composition.',fit:'contain',position:{left:130,top:120,width:1020,height:565}});
note(6,'Original Figure 2 from the supplied manuscript. Three target pathologies: cardiomegaly, emphysema and pneumothorax. Each has 200 fixed queries. Every gallery contains 20,000 images with 1,000, 400, 200 or 100 relevant cases. Three non-target pathology distractors each contribute 400 images. Five seeds per target and prevalence yield 60 galleries. All six models use the same manifests. Tuberculosis was excluded as a target after a source-bias audit but remained a 2% distractor.');
const tab=ss[6].tables.items[0];
const vals=[['Item','Details'],['Data and queries','NIH ChestX-ray14, SIIM-ACR and three external collections.\n200 fixed queries per pathology.'],['Image preparation','224 × 224, grayscale in 3 channels, ImageNet normalization.\nDuplicate audit and patient exclusions where identifiers permit.'],['Six representations','CNN-PT, CNN-Common, CNN-NIH, SwAV-PT,\nSwAV-CLS and SwAV-SupCon.'],['Retrieval and metrics','2,048-D normalized embeddings, exact cosine ranking.\nPrecision@10 primary, nDCG@10 secondary.'],['Training and inference','AdamW, learning rate 0.0001, up to 50 epochs.\nOne training run per learned condition, five gallery seeds.']];
for(let r=0;r<6;r++)for(let c=0;c<2;c++)tab.cells.set(r,c,vals[r][c]);
tab.position={left:57.6,top:150,width:1164.48,height:450};
for(let r=0;r<6;r++)tab.rows[r].height=r===0?54:80;
note(7,'CNN-PT: supervised ImageNet ResNet-50 without adaptation. CNN-Common: three-class normal/pneumonia/COVID-19 classification. CNN-NIH: NIH multi-label classification. SwAV-PT: self-supervised ImageNet ResNet-50 without adaptation. SwAV-CLS: NIH multi-label classification from SwAV. SwAV-SupCon: weighted multi-label supervised contrastive learning from SwAV. The projection head is discarded for retrieval. Common-class adaptation used 4,545 balanced images and an 80:20 source-class-stratified split. NIH adaptation used 48,280 training and 12,266 validation images after target-patient exclusions, with 10,620 background images. Training used PyTorch 2.10.0+cu128 and two Tesla T4 GPUs. The five gallery seeds are not independent training runs. Paired query tests use Holm correction, with 72 planned model comparisons.');
title(8,'Precision Falls as Cases Become Rarer');
const l8=JSON.parse(await(await ss[7].export({format:'layout'})).text());
for(const c of l8.elements)if(c.kind==='chart')p.delete(c.id);
const chart=ss[7].charts.add('bar',{position:{left:57.6,top:151,width:730,height:465},title:'SwAV-SupCon Precision@10',titleTextStyle:{fontSize:23,fill:'#0B2545'},categories:['Cardiomegaly','Emphysema','Pneumothorax'],series:[{name:'5% prevalence',values:[.1597,.2377,.4140],fill:'#0B2545'},{name:'0.5% prevalence',values:[.0163,.0335,.0660],fill:'#547FA9'}],barOptions:{direction:'column',grouping:'clustered',gapWidth:90},hasLegend:true,legend:{position:'bottom',textStyle:{fontSize:18}},yAxis:{min:0,max:.45,majorUnit:.1,numberFormatCode:'0.00',textStyle:{fontSize:17},majorGridlines:{fill:'#D8DFE8',width:1}},xAxis:{textStyle:{fontSize:17}},dataLabels:{showValue:true,position:'outEnd',numberFormatCode:'0.0000',textStyle:{fontSize:17}},chartFill:'#FAFAFA',plotAreaFill:'#FAFAFA'});
set(8,'Takeaway text','All six models declined\n\nP@10 fell by 83.4%–91.9% from 5% to 0.5% prevalence across the 18 model–pathology pairs.\n\nEvery paired decline remained significant after Holm correction.\n\nAt 0.5%, random P@10 = 0.005.',22);
note(8,'Endpoint values come from manuscript Table 2. The chart shows SwAV-SupCon, the highest mean model at every pathology-prevalence condition. All 18 included model-pathology pairs declined significantly for both metrics, Holm-adjusted p ≤ 2.30 × 10^-26. Across all models, absolute P@10 loss ranged from 0.0959 to 0.3480. The larger absolute loss for a stronger model does not establish poorer rare-case retrieval: SwAV-SupCon remained highest at both endpoints. The chart presents means across five gallery samples without uncertainty bars. Seed variation measures gallery sampling, not retraining. Pneumothorax uses SIIM queries and an NIH relevant gallery and is a cross-source condition.');
title(9,'SwAV-SupCon Leads Within This Study');
set(9,'Stat value 1','12/12');set(9,'Stat label 1','Highest mean P@10');set(9,'Stat note 1','All pathology–prevalence\nconditions');
set(9,'Stat value 2','10/12');set(9,'Stat label 2','Above SwAV-CLS');set(9,'Stat note 2','Significant after global\nHolm correction');
set(9,'Stat value 3','3.26–13.20×',44);set(9,'Stat label 3','Random enrichment');set(9,'Stat note 3','At 0.5% prevalence,\nP@10 = 0.0163–0.0660');
note(9,'SwAV-SupCon ranked first in mean P@10 in all 12 conditions. Its advantage over SwAV-CLS survived global correction in 10 of 12 planned comparisons. The exceptions were cardiomegaly at 0.5% and 1%. At 0.5%, SupCon versus CLS P@10: cardiomegaly 0.0163 versus 0.0133 (adjusted p > 0.99), emphysema 0.0335 versus 0.0175 (p = 5.34 × 10^-7), pneumothorax 0.0660 versus 0.0446 (p = 3.17 × 10^-6). Enrichment factors 3.26, 6.70 and 13.20 divide the leading mean by the random expectation of 0.005. Low absolute precision limits practical interpretation. Results are conditional on one fitted checkpoint per learned condition and objective-specific checkpoint selection.');
body(10,'Conclusion\nLower target prevalence substantially reduces retrieval quality.\nSwAV-SupCon leads here, but rare-case precision remains limited.\nLimits\nOne training run, imperfect labels and cross-source confounding.\nFuture work\nRepeat training, strengthen source controls and assess clinical relevance.');
note(10,'Additional limitations: every model uses ResNet-50, external labels are not exhaustive, SIIM patient uniqueness cannot be verified, and no clinician assessed relevance. Pneumothorax source is aligned with query-gallery role, so the result is not a source-controlled estimate of pathology-specific similarity. The lowest prevalence still has 100 relevant images, and larger approximate indexes were not evaluated. No study measured diagnostic benefit. Future work should test additional architectures, lower relevant-case counts and clinically assessed relevance.');
const refs=(await fs.readFile(path.join(build,'paper.txt'),'utf8')).split('\n').filter(x=>/^\[(1|9|10|11|12)\]/.test(x));
body(11,refs.join('\n\n'));
note(11,'These references follow the manuscript bibliography. The remaining related-work and dataset references are in the paper.');
set(12,'Contact','Ofei Obuobisah Bekoe\nce-pobekoe1423@st.umat.edu.gh\nUniversity of Mines and Technology, Ghana',23);
sh(12,'Contact').position={left:526,top:405,width:680,height:120};
note(12,'Thank the audience and invite discussion about prevalence-aware benchmarking, representation adaptation and cross-source evaluation.');
await fs.mkdir(path.join(build,'final-previews'),{recursive:true});
const candidate=path.join(build,'candidate.pptx');await(await PresentationFile.exportPptx(p)).save(candidate);
console.log('DRAFT SAVED');
for(let i=0;i<ss.length;i++){
 await fs.writeFile(path.join(build,'final-previews',`${i+1}.png`),new Uint8Array(await(await ss[i].export({format:'png',scale:1})).arrayBuffer()));
 console.log('RENDER',i+1);
}
const {finalizePresentation}=await import(pathToFileURL(path.join(skill,'container_tools/artifact_tool_utils.mjs')).href);
await fs.mkdir(path.join(root,'outputs'),{recursive:true});
const result=await finalizePresentation({workspaceDir:root,candidatePath:candidate,finalPath:path.join(root,'outputs','ICAST2026_Chest_XRay_Retrieval.pptx'),pythonExecutable:'C:/Users/Papa Offei/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe',integrityValidatorPath:path.join(skill,'container_tools/inspect_presentation_package_integrity.py'),layoutValidatorPath:path.join(skill,'container_tools/inspect_presentation_layout_geometry.py'),layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-bullet-geometry','--validate-heading-fit'],requiredNativeTableOwnerSlides:[7],requiredNativeChartOwnerSlides:[8],materializeLiteralChartWorkbooks:true,fontPolicy:{basis:'reference',families:['Roboto'],referencePath:src,referenceSha256:crypto.createHash('sha256').update(await fs.readFile(src)).digest('hex')},verifyArtifactToolImport:true,receiptPath:path.join(build,'validation.json')});
console.log(JSON.stringify(result));
