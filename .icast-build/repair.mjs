import fs from 'node:fs/promises';
import {FileBlob,PresentationFile} from '@oai/artifact-tool';
import {applyPresentationChartFont} from 'file:///C:/Users/Papa%20Offei/.codex/plugins/cache/openai-primary-runtime/presentations/26.1013.11914/skills/presentations/container_tools/artifact_tool_utils.mjs';
process.on('uncaughtException',e=>{console.error(e.message);process.exit(1)});
const p=await PresentationFile.importPptx(await FileBlob.load('.icast-build/candidate.pptx'));
const s=p.slides.items[5],l=JSON.parse(await(await s.export({format:'layout'})).text());
console.log(l.elements.map(x=>({id:x.id,kind:x.kind,name:x.name,scope:x.scope,editable:x.editable})));
for(const x of l.elements)if(x.position.top>110&&x.name!=='Slide Number')p.delete(x.id);
function text(sl,name,t,x,y,w,h,size=27){const q=sl.shapes.add({name,geometry:'textbox',position:{left:x,top:y,width:w,height:h},fill:'none',line:{fill:'none',width:0}});q.text=t;q.text.style={fontFamily:'Roboto',fontSize:size,color:'#333333'};return q;}
text(s,'Fixed protocol','200 fixed queries per target\n\n20,000 images per gallery\n\nFive gallery samples per condition\n\nSame six fitted models throughout',60,165,530,300,27);
const t=s.tables.add({rows:5,columns:2,left:650,top:160,width:560,height:340,columnWidths:[280,280],values:[['Prevalence','Relevant images'],['5%','1,000'],['2%','400'],['1%','200'],['0.5%','100']]});
t.borders.assign({fill:'#CBD5E1',width:1});
for(let r=0;r<5;r++)for(let c=0;c<2;c++){const ce=t.getCell(r,c);ce.fill=r===0?'#0B2545':'#FFFFFF';ce.text.style={fontFamily:'Roboto',fontSize:25,color:r===0?'#FFFFFF':'#333333',bold:r===0};}
text(s,'Targets','Cardiomegaly, emphysema and pneumothorax',60,535,1150,48,27);
text(s,'Control details','Each non-target pathology contributes 400 distractors. Background images fill the remaining positions.\n3 targets × 4 prevalence levels × 5 gallery samples = 60 galleries.',60,595,1150,84,21);
const s8=p.slides.items[7];s8.shapes.items.find(x=>x.name==='Text 1').text='Precision Falls at Lower Prevalence';
applyPresentationChartFont(s8.charts.items[0],{fontFamily:'Roboto'});
const s10=p.slides.items[9],bl=JSON.parse(await(await s10.export({format:'layout'})).text());
for(const x of bl.elements)if(x.name==='Text 1'&&x.position.top>110)p.delete(x.id);
text(s10,'Conclusion heading','Conclusion',58,150,1160,45,28).text.style={fontFamily:'Roboto',fontSize:28,color:'#0B2545',bold:true};
text(s10,'Conclusion text','Lower prevalence substantially reduces retrieval quality.\nSwAV-SupCon leads here, but rare-case precision remains limited.',58,206,1160,95,27);
text(s10,'Limits heading','Study limits',58,326,1160,45,28).text.style={fontFamily:'Roboto',fontSize:28,color:'#0B2545',bold:true};
text(s10,'Limits text','One training run per condition, imperfect labels and cross-source confounding.',58,380,1160,75,27);
text(s10,'Future heading','Future work',58,476,1160,45,28).text.style={fontFamily:'Roboto',fontSize:28,color:'#0B2545',bold:true};
text(s10,'Future text','Repeat training, strengthen source controls and assess clinical relevance.',58,530,1160,90,27);
for(const i of [6,8,10])await fs.writeFile(`.icast-build/final-previews/${i}.png`,new Uint8Array(await(await p.slides.items[i-1].export({format:'png',scale:1})).arrayBuffer()));
await(await PresentationFile.exportPptx(p)).save('.icast-build/candidate-repaired.pptx');
console.log('REPAIRED');

